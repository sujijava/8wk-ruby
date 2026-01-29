# ============================================================================
# PRODUCTION-GRADE RATE LIMITER - FAANG INTERVIEW STANDARD
# ============================================================================
#
# Problem Statement:
# ------------------
# Design and implement a production-ready rate limiter that prevents API abuse
# and ensures fair resource allocation. This is a classic system design problem
# asked at Meta, Google, Stripe, Twitter/X, and other FAANG companies.
#
# Your rate limiter must support multiple algorithms and be suitable for
# production use with millions of API requests per second.
#
# Real-World Context:
# -------------------
# Rate limiters are critical infrastructure at scale:
#
# • Stripe API: Prevents abuse, ensures fair usage across customers
# • Twitter API: Rate limits per user/app to prevent spam and abuse
# • GitHub API: Different rate limits for authenticated vs unauthenticated
# • AWS API Gateway: Throttles requests to protect backend services
# • Redis: Uses token bucket for replication traffic control
#
# A production rate limiter must be:
# - Fast (< 1ms per decision)
# - Accurate (no over-limiting or under-limiting)
# - Memory efficient (handle millions of users)
# - Thread-safe (concurrent requests)
# - Testable (especially time-based behavior)
#
# Requirements:
# -------------
# Implement THREE rate limiting algorithms:
#
# 1. FIXED WINDOW COUNTER
#    - Track request count in fixed time windows (e.g., per minute)
#    - Simple but has "burst" problem at window boundaries
#    - Example: 100 requests/minute
#    - Edge case: 100 requests at 00:59, 100 at 01:00 = 200 req/minute!
#
# 2. SLIDING WINDOW LOG
#    - Track timestamps of all requests in a sliding window
#    - Accurate but memory-intensive
#    - Example: Exactly 100 requests in any 60-second window
#    - Trade-off: Memory grows with request volume
#
# 3. TOKEN BUCKET (BONUS)
#    - Tokens added at fixed rate, consumed per request
#    - Allows bursts up to bucket capacity
#    - Example: 10 tokens/sec, bucket size 100 (allows 100 burst)
#    - Used by AWS, Google Cloud, many production systems
#
# Key Design Decisions:
# ---------------------
# 1. How to handle time? (Clock injection for testing)
# 2. How to store request history? (Memory vs accuracy trade-off)
# 3. How to clean up old data? (Prevent memory leaks)
# 4. Thread safety? (Ruby GIL helps, but still need atomicity)
# 5. Configuration? (Per-user limits, endpoint limits, global limits)
#
# Testing Requirements:
# ---------------------
# Your tests must cover:
# - Basic rate limiting (allow/deny decisions)
# - Window boundaries (edge cases)
# - Time advancement (clock injection)
# - Concurrent requests (thread safety)
# - Memory cleanup (no leaks)
# - Multiple users/keys
# - Different time windows (second, minute, hour)
#
# Common Pitfalls:
# ----------------
# ❌ Using Time.now directly (makes testing impossible)
# ✅ Inject clock dependency for testability
#
# ❌ Not cleaning up old timestamps (memory leak)
# ✅ Implement cleanup logic
#
# ❌ Off-by-one errors at window boundaries
# ✅ Use precise time comparisons
#
# ❌ Not handling concurrent requests
# ✅ Use thread-safe operations
#
# Interview Discussion Points:
# -----------------------------
# Be ready to discuss:
# - Space vs time complexity of each algorithm
# - How to distribute rate limiter across multiple servers
# - Using Redis for distributed rate limiting
# - How to handle clock skew in distributed systems
# - Rate limiting vs circuit breakers vs backpressure
# - Graceful degradation when rate limiter fails
#
# Success Criteria:
# -----------------
# Your implementation should:
# 1. Pass all test cases (100+ assertions)
# 2. Support multiple algorithms
# 3. Be thread-safe
# 4. Be memory efficient
# 5. Be testable (clock injection)
# 6. Handle edge cases correctly
# 7. Have O(1) or O(log n) time complexity for allow? check
#
# Time Expectation:
# -----------------
# - 45-60 minutes for core implementation (Fixed Window + Sliding Window)
# - 75-90 minutes for all three algorithms + comprehensive tests
# - Be ready to explain trade-offs and discuss distributed scenarios
#
# ============================================================================

require 'time'

# ============================================================================
# YOUR IMPLEMENTATION GOES HERE
# ============================================================================
#
# Recommended Structure:
#
# class RateLimiter
#   def initialize(strategy:, max_requests:, window_size_seconds:, clock: Time)
#     # Store strategy (FixedWindow, SlidingWindow, TokenBucket)
#     # Store configuration (limits, window size)
#     # Store clock for time injection (testability)
#   end
#
#   def allow?(key)
#     # Delegate to strategy
#   end
#
#   def reset!(key)
#     # Clear history for key
#   end
#
#   def current_usage(key)
#     # Return current request count/tokens for monitoring
#   end
# end
#
# class FixedWindowStrategy
#   def initialize(max_requests:, window_size_seconds:, clock:)
#   end
#
#   def allow?(key)
#     # Calculate current window
#     # Check if under limit
#     # Increment counter
#   end
# end
#
# class SlidingWindowStrategy
#   def initialize(max_requests:, window_size_seconds:, clock:)
#   end
#
#   def allow?(key)
#     # Remove old timestamps
#     # Check if under limit
#     # Add new timestamp
#   end
# end
#
# class TokenBucketStrategy (BONUS)
#   def initialize(refill_rate:, bucket_capacity:, clock:)
#   end
#
#   def allow?(key)
#     # Refill tokens based on elapsed time
#     # Check if token available
#     # Consume token if available
#   end
# end
#
# ============================================================================

# Write your implementation here

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

$test_count = 0
$failure_count = 0
$current_section = ""

def section(name)
  $current_section = name
  puts "\n" + "=" * 80
  puts "  #{name}"
  puts "=" * 80
end

def test(description)
  $test_count += 1
  yield
  print "."
rescue => e
  $failure_count += 1
  puts "\n\n❌ FAILURE in #{$current_section}: #{description}"
  puts "  #{e.class}: #{e.message}"
  puts "\n  Backtrace:"
  e.backtrace.first(5).each { |line| puts "    #{line}" }
end

def assert_equal(expected, actual, message = nil)
  unless expected == actual
    raise "#{message}\n  Expected: #{expected.inspect}\n  Actual:   #{actual.inspect}"
  end
end

def assert_true(condition, message = "Expected true")
  raise message unless condition
end

def assert_false(condition, message = "Expected false")
  raise message if condition
end

def assert_nil(value, message = "Expected nil")
  raise "#{message}\n  Got: #{value.inspect}" unless value.nil?
end

def assert_raises(exception_class)
  yield
  raise "Expected #{exception_class} to be raised but nothing was raised"
rescue exception_class => e
  # Success
  return e
rescue => e
  raise "Expected #{exception_class} but got #{e.class}: #{e.message}"
end

# ============================================================================
# MOCK CLOCK FOR TESTING
# ============================================================================
# This allows us to test time-based behavior without actually waiting

class MockClock
  attr_accessor :current_time

  def initialize(start_time = Time.now)
    @current_time = start_time
  end

  def now
    @current_time
  end

  def advance(seconds)
    @current_time += seconds
  end
end

# ============================================================================
# COMPREHENSIVE TEST SUITE
# ============================================================================

puts "\n" + "=" * 80
puts "RATE LIMITER TEST SUITE - FAANG INTERVIEW STANDARD"
puts "=" * 80

# ----------------------------------------------------------------------------
# SECTION 1: FIXED WINDOW COUNTER TESTS
# ----------------------------------------------------------------------------

section "Section 1: Fixed Window Counter - Basic Functionality"

# Test 1: Allow requests under limit
test("should allow requests under the limit") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  assert_true limiter.allow?("user1"), "First request should be allowed"
  assert_true limiter.allow?("user1"), "Second request should be allowed"
  assert_true limiter.allow?("user1"), "Third request should be allowed"
end

# Test 2: Deny requests over limit
test("should deny requests over the limit") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 2,
    window_size_seconds: 60,
    clock: clock
  )

  limiter.allow?("user1")
  limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "Third request should be denied"
end

# Test 3: Reset on new window
test("should reset counter in new window") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 2,
    window_size_seconds: 60,
    clock: clock
  )

  limiter.allow?("user1")
  limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "Should be denied in current window"

  clock.advance(60)  # Move to next window
  assert_true limiter.allow?("user1"), "Should be allowed in new window"
end

# Test 4: Multiple users isolated
test("should track different users independently") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 2,
    window_size_seconds: 60,
    clock: clock
  )

  limiter.allow?("user1")
  limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "user1 should be limited"
  assert_true limiter.allow?("user2"), "user2 should not be affected"
end

# Test 5: Window boundary edge case (the burst problem)
test("should demonstrate burst problem at window boundaries") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  # Make 3 requests at end of window (t=59)
  clock.current_time = Time.at(59)
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")

  # Immediately make 3 more at start of next window (t=60)
  clock.current_time = Time.at(60)
  assert_true limiter.allow?("user1"), "New window allows more requests"
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")

  # Result: 6 requests in 2 seconds (burst problem!)
end

# Test 6: Current usage tracking
test("should track current usage") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 5,
    window_size_seconds: 60,
    clock: clock
  )

  assert_equal 0, limiter.current_usage("user1"), "Should start at 0"
  limiter.allow?("user1")
  assert_equal 1, limiter.current_usage("user1"), "Should increment"
  limiter.allow?("user1")
  assert_equal 2, limiter.current_usage("user1"), "Should increment again"
end

# Test 7: Reset functionality
test("should reset user's rate limit") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 2,
    window_size_seconds: 60,
    clock: clock
  )

  limiter.allow?("user1")
  limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "Should be limited"

  limiter.reset!("user1")
  assert_true limiter.allow?("user1"), "Should work after reset"
end

# ----------------------------------------------------------------------------
# SECTION 2: SLIDING WINDOW LOG TESTS
# ----------------------------------------------------------------------------

section "Section 2: Sliding Window Log - Accurate Rate Limiting"

# Test 8: Accurate sliding window
test("should enforce exact sliding window") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  # Make 3 requests at t=0
  clock.current_time = Time.at(0)
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "Should be limited at t=0"

  # At t=30, still should be limited (window is last 60 seconds)
  clock.current_time = Time.at(30)
  assert_false limiter.allow?("user1"), "Should still be limited at t=30"

  # At t=61, first request (from t=0) should expire
  clock.current_time = Time.at(61)
  assert_true limiter.allow?("user1"), "Should allow after first request expires"
end

# Test 9: No burst problem with sliding window
test("should not have burst problem at boundaries") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  # Make 3 requests at t=59
  clock.current_time = Time.at(59)
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")
  assert_true limiter.allow?("user1")

  # Try to make more at t=60 (should fail - requests from t=59 still in window)
  clock.current_time = Time.at(60)
  assert_false limiter.allow?("user1"), "Should be denied - sliding window prevents burst"
end

# Test 10: Old timestamps cleanup
test("should clean up old timestamps") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 100,
    window_size_seconds: 60,
    clock: clock
  )

  # Make many requests
  50.times { limiter.allow?("user1") }

  # Advance far into future
  clock.advance(1000)

  # Make one more request (should trigger cleanup)
  limiter.allow?("user1")

  # Verify old data cleaned up (implementation-specific)
  # You might expose a method like limiter.timestamp_count("user1")
  # assert_equal 1, limiter.timestamp_count("user1"), "Should clean old timestamps"
end

# Test 11: Precise timestamp tracking
test("should track requests with precise timestamps") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 2,
    window_size_seconds: 10,
    clock: clock
  )

  clock.current_time = Time.at(0)
  limiter.allow?("user1")

  clock.current_time = Time.at(5)
  limiter.allow?("user1")
  assert_false limiter.allow?("user1"), "Should be limited"

  # At t=10.1, first request (t=0) expires
  clock.current_time = Time.at(10.1)
  assert_true limiter.allow?("user1"), "Request from t=0 should be expired"
end

# ----------------------------------------------------------------------------
# SECTION 3: EDGE CASES & ROBUSTNESS
# ----------------------------------------------------------------------------

section "Section 3: Edge Cases & Robustness"

# Test 12: Zero requests allowed
test("should handle zero request limit") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 0,
    window_size_seconds: 60,
    clock: clock
  )

  assert_false limiter.allow?("user1"), "Should deny all requests"
end

# Test 13: Very large window
test("should handle large time windows") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 1,
    window_size_seconds: 86400,  # 1 day
    clock: clock
  )

  limiter.allow?("user1")
  clock.advance(3600)  # 1 hour later
  assert_false limiter.allow?("user1"), "Should still be limited after 1 hour"

  clock.advance(86400)  # 1 day later
  assert_true limiter.allow?("user1"), "Should reset after window"
end

# Test 14: Very small window
test("should handle small time windows") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 2,
    window_size_seconds: 1,  # 1 second
    clock: clock
  )

  clock.current_time = Time.at(0)
  limiter.allow?("user1")
  limiter.allow?("user1")

  clock.current_time = Time.at(0.5)
  assert_false limiter.allow?("user1"), "Should be limited"

  clock.current_time = Time.at(1.1)
  assert_true limiter.allow?("user1"), "Should allow after 1 second"
end

# Test 15: Nil/empty keys
test("should handle edge case keys") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 2,
    window_size_seconds: 60,
    clock: clock
  )

  assert_true limiter.allow?(""), "Should handle empty string"
  assert_true limiter.allow?("special-chars-!@#$%"), "Should handle special chars"
  assert_true limiter.allow?("very" * 100), "Should handle long keys"
end

# Test 16: Very high request volume
test("should handle high request volume") do
  clock = MockClock.new(Time.at(0))
  limiter = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 1000,
    window_size_seconds: 60,
    clock: clock
  )

  allowed_count = 0
  1200.times do
    allowed_count += 1 if limiter.allow?("user1")
  end

  assert_equal 1000, allowed_count, "Should allow exactly max_requests"
end

# ----------------------------------------------------------------------------
# SECTION 4: DIFFERENT STRATEGIES COMPARISON
# ----------------------------------------------------------------------------

section "Section 4: Strategy Comparison"

# Test 17: Same configuration, different behavior at boundaries
test("should show different behavior between Fixed and Sliding Window") do
  clock = MockClock.new(Time.at(0))

  fixed = RateLimiter.new(
    strategy: FixedWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  sliding = RateLimiter.new(
    strategy: SlidingWindowStrategy,
    max_requests: 3,
    window_size_seconds: 60,
    clock: clock
  )

  # Both make 3 requests at t=59
  clock.current_time = Time.at(59)
  3.times do
    fixed.allow?("user1")
    sliding.allow?("user1")
  end

  # At t=60, fixed window resets, sliding window does not
  clock.current_time = Time.at(60)

  assert_true fixed.allow?("user1"), "Fixed window allows (new window)"
  assert_false sliding.allow?("user1"), "Sliding window denies (requests still in window)"
end

# ----------------------------------------------------------------------------
# SECTION 5: BONUS - TOKEN BUCKET (if implemented)
# ----------------------------------------------------------------------------

section "Section 5: BONUS - Token Bucket Strategy"

begin
  # Test 18: Token bucket basic
  test("should allow burst up to bucket capacity") do
    clock = MockClock.new(Time.at(0))
    limiter = RateLimiter.new(
      strategy: TokenBucketStrategy,
      refill_rate: 1,  # 1 token per second
      bucket_capacity: 10,
      clock: clock
    )

    # Should allow burst of 10
    10.times do |i|
      assert_true limiter.allow?("user1"), "Should allow burst request #{i+1}"
    end

    assert_false limiter.allow?("user1"), "Should deny 11th request"
  end

  # Test 19: Token refill
  test("should refill tokens over time") do
    clock = MockClock.new(Time.at(0))
    limiter = RateLimiter.new(
      strategy: TokenBucketStrategy,
      refill_rate: 2,  # 2 tokens per second
      bucket_capacity: 10,
      clock: clock
    )

    # Use all tokens
    10.times { limiter.allow?("user1") }
    assert_false limiter.allow?("user1")

    # Wait 1 second (should get 2 tokens back)
    clock.advance(1)
    assert_true limiter.allow?("user1"), "Should get token back"
    assert_true limiter.allow?("user1"), "Should have 2 tokens"
    assert_false limiter.allow?("user1"), "Should be out again"
  end

  # Test 20: Token bucket doesn't exceed capacity
  test("should not exceed bucket capacity") do
    clock = MockClock.new(Time.at(0))
    limiter = RateLimiter.new(
      strategy: TokenBucketStrategy,
      refill_rate: 10,  # 10 tokens per second
      bucket_capacity: 5,
      clock: clock
    )

    # Wait long time
    clock.advance(100)

    # Should only allow bucket_capacity requests
    5.times { assert_true limiter.allow?("user1") }
    assert_false limiter.allow?("user1"), "Should not exceed capacity"
  end

rescue NameError => e
  puts "\n  ⏭️  Skipping Token Bucket tests (not implemented)"
  puts "     To implement: Create TokenBucketStrategy class"
end

# ============================================================================
# TEST SUMMARY
# ============================================================================

puts "\n\n" + "=" * 80
puts "TEST RESULTS"
puts "=" * 80

if $failure_count == 0
  puts "✅ ALL #{$test_count} TESTS PASSED!"
  puts "\n🎯 What this demonstrates:"
  puts "   • Fixed Window Counter (simple, fast, but has burst problem)"
  puts "   • Sliding Window Log (accurate, no burst, but memory intensive)"
  puts "   • Clock injection for testability"
  puts "   • Edge case handling"
  puts "   • Production-ready design"
  puts "\n💡 Discussion Points for Interview:"
  puts "   • Space/time complexity: Fixed O(1), Sliding O(n) where n=requests in window"
  puts "   • Distributed rate limiting: Use Redis with INCR, EXPIRE commands"
  puts "   • Trade-offs: Memory vs accuracy, simplicity vs precision"
  puts "   • Real-world: Token bucket preferred for burst tolerance"
  puts "\n🚀 Next Steps:"
  puts "   • Implement Token Bucket strategy"
  puts "   • Add thread-safety with Mutex"
  puts "   • Implement Redis-backed distributed version"
  puts "   • Add metrics/monitoring hooks"
  puts "   • Handle edge cases: clock drift, distributed consensus"

  exit 0
else
  puts "❌ #{$failure_count} TEST(S) FAILED (out of #{$test_count} total)"
  puts "\nCommon issues:"
  puts "  • Not injecting clock dependency"
  puts "  • Not cleaning up old timestamps"
  puts "  • Off-by-one errors in window calculations"
  puts "  • Not handling window boundaries correctly"

  exit 1
end
