# Week 1, Day 1: Blocks, Procs, Lambdas
# Exercise: Build a retry mechanism with exponential backoff
#
# CONTEXT (Real pair-programming scenario):
# "We have a microservices architecture where services occasionally fail due to
# network issues or temporary unavailability. We need a reusable retry mechanism
# that can wrap any API call and automatically retry with exponential backoff.
#
# This is a simplified version of what we use in production. We'd like you to
# implement the core retry logic."
#
# REQUIREMENTS:
# 1. Create a `with_retry` method that takes options and a block
# 2. Options: max (max retries), delay (initial delay in seconds)
# 3. On exception, wait with exponential backoff: delay, delay*2, delay*4, etc.
# 4. Re-raise the exception if max retries exceeded
# 5. Return the block's result if successful
#
# EXAMPLE USAGE:
#   result = with_retry(max: 3, delay: 1) do
#     some_flaky_api_call
#   end
#
# DISCUSSION POINTS (think about these):
# - What exceptions should we catch? All of them? Specific ones?
# - Should we log retry attempts?
# - How would you make this configurable per exception type?
# - Block vs Proc vs Lambda - when would you use each?

class RetryMechanism
  # TODO: Implement this method
  def self.with_retry(max: 3, delay: 1)
   attempt = 0

   begin
    yield
   rescue StandardError => e
    attempt += 1
    raise e if attempt >= max
    sleep(delay * (2 ** (attempt -1)))
    retry
   end
  end
end

# Simulated flaky API (for testing purposes)
class FlakyAPI
  def self.call(fail_times: 2)
    @attempts ||= 0
    @attempts += 1

    if @attempts <= fail_times
      raise StandardError, "API call failed (attempt #{@attempts})"
    end

    @attempts = 0 # reset for next test
    "Success!"
  end

  def self.always_fails
    raise StandardError, "This always fails"
  end
end

# Manual testing examples (uncomment to test):
if __FILE__ == $0
  puts "Testing retry mechanism...\n\n"

  # Test 1: Should succeed after retries
  # puts "Test 1: API that fails 2 times, then succeeds"
  # begin
  #   result = RetryMechanism.with_retry(max: 3, delay: 0.5) do
  #     FlakyAPI.call(fail_times: 2)
  #   end
  #   puts "✓ Result: #{result}"
  # rescue => e
  #   puts "✗ Failed: #{e.message}"
  # end

  # Test 2: Should raise after max retries
  # puts "\nTest 2: API that always fails"
  # begin
  #   result = RetryMechanism.with_retry(max: 2, delay: 0.5) do
  #     FlakyAPI.always_fails
  #   end
  #   puts "✓ Result: #{result}"
  # rescue => e
  #   puts "✓ Correctly raised: #{e.message}"
  # end
end
