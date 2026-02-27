# ============================================================================
# WEATHER SERVICE API WRAPPER - TESTING EXTERNAL DEPENDENCIES
# ============================================================================
#
# Problem Statement:
# ------------------
# You're building a production-ready WeatherService that wraps the OpenWeather
# API. In pairing interviews, you'll often need to write tests for code that
# depends on external services. This exercise teaches you to:
#
# 1. Stub external HTTP calls effectively
# 2. Test error scenarios (timeouts, rate limits, malformed responses)
# 3. Implement and test retry logic with exponential backoff
# 4. Use recording/playback patterns (VCR-style) for integration tests
# 5. Handle API authentication and error codes properly
#
# Real-World Context:
# -------------------
# At FAANG companies, you'll work with dozens of external APIs:
# - Payment processors (Stripe, PayPal)
# - Communication services (Twilio, SendGrid)
# - Cloud providers (AWS, GCP)
# - Analytics platforms (Segment, Mixpanel)
#
# Tests must run fast, be deterministic, and not hit real APIs in CI/CD.
# You need to prove you can test external dependencies without making your
# test suite flaky or slow.
#
# Requirements:
# -------------
# Implement comprehensive tests for the WeatherService class below.
# The class is already implemented - your job is to write thorough tests.
#
# Key Testing Scenarios:
# ----------------------
# 1. HAPPY PATH
#    - Successfully fetch current weather
#    - Successfully fetch forecast
#    - Verify correct data extraction from API response
#    - Handle different temperature units (celsius/fahrenheit)
#
# 2. STUBBING/MOCKING
#    - Stub HTTP calls to avoid hitting real API
#    - Mock different response scenarios
#    - Verify correct HTTP headers (API key, content-type)
#    - Ensure no real network calls during tests
#
# 3. ERROR HANDLING
#    - Network timeouts (connection timeout, read timeout)
#    - Rate limiting (429 status code)
#    - Authentication errors (401 - invalid API key)
#    - Not found errors (404 - city not found)
#    - Server errors (500, 502, 503)
#    - Malformed JSON responses
#    - Missing required fields in response
#
# 4. RETRY LOGIC
#    - Retries on transient failures (500, 502, 503, timeout)
#    - Does NOT retry on permanent failures (401, 404)
#    - Exponential backoff between retries
#    - Max retry limit respected
#    - Logs retry attempts
#
# 5. CACHING (BONUS)
#    - Cache responses for configurable TTL
#    - Return cached data when available
#    - Cache invalidation on errors
#    - Different cache keys for different queries
#
# 6. VCR/RECORDING PATTERN (ADVANCED)
#    - Record real API responses to fixtures
#    - Replay from fixtures in tests
#    - Update fixtures when schema changes
#
# Testing Principles for External APIs:
# --------------------------------------
# ✅ DO:
#    - Test business logic in isolation from HTTP layer
#    - Stub at the HTTP client level (Net::HTTP, HTTParty, etc.)
#    - Test all error branches
#    - Use realistic response fixtures
#    - Test timeout scenarios
#    - Verify retry behavior
#
# ❌ DON'T:
#    - Hit real APIs in unit tests (slow, flaky, costs money)
#    - Over-mock (don't mock everything, test real logic)
#    - Use brittle JSON string matching
#    - Ignore error scenarios
#    - Forget to test headers/authentication
#
# Time Expectation:
# -----------------
# - 60-75 minutes for comprehensive test suite
# - Focus on edge cases and error scenarios
# - Practice explaining tradeoffs between stubbing approaches
#
# ============================================================================

require 'net/http'
require 'json'
require 'uri'
require 'pry'

# ============================================================================
# WEATHER SERVICE IMPLEMENTATION
# ============================================================================
# This is production-grade code you might see in a pairing interview.
# Your job is to write comprehensive tests for it.

class WeatherService
  class APIError < StandardError; end
  class RateLimitError < APIError; end
  class AuthenticationError < APIError; end
  class NotFoundError < APIError; end
  class TimeoutError < APIError; end
  class ServerError < APIError; end

  BASE_URL = 'https://api.openweathermap.org/data/2.5'
  DEFAULT_TIMEOUT = 5
  MAX_RETRIES = 3
  RETRY_DELAY = 0.5 # seconds

  attr_reader :api_key, :cache

  def initialize(api_key:, timeout: DEFAULT_TIMEOUT, cache: nil)
    raise ArgumentError, "API key cannot be blank" if api_key.nil? || api_key.empty?
    @api_key = api_key
    @timeout = timeout
    @cache = cache || {}
  end

  # Fetch current weather for a city
  # @param city [String] City name (e.g., "London", "San Francisco")
  # @param units [String] Temperature units: 'metric' (Celsius) or 'imperial' (Fahrenheit)
  # @return [Hash] Weather data with temperature, description, humidity, etc.
  def current_weather(city, units: 'metric')
    validate_city!(city)
    validate_units!(units)

    cache_key = "current:#{city}:#{units}"
    return cache[cache_key] if cache[cache_key]

    params = { q: city, units: units, appid: api_key }
    response = make_request('/weather', params)

    data = parse_current_weather(response)
    cache[cache_key] = data
    data
  end

  # Fetch 5-day forecast for a city
  # @param city [String] City name
  # @param units [String] Temperature units
  # @return [Array<Hash>] Array of forecast data points
  def forecast(city, units: 'metric')
    validate_city!(city)
    validate_units!(units)

    cache_key = "forecast:#{city}:#{units}"
    return cache[cache_key] if cache[cache_key]

    params = { q: city, units: units, appid: api_key }
    response = make_request('/forecast', params)

    data = parse_forecast(response)
    cache[cache_key] = data
    data
  end

  # Clear the response cache
  def clear_cache!
    @cache.clear
  end

  private

  def make_request(endpoint, params, retry_count = 0)
    uri = build_uri(endpoint, params)

    response = with_timeout do
      Net::HTTP.get_response(uri)
    end

    handle_response(response)

  rescue Timeout::Error, Errno::ETIMEDOUT
    raise TimeoutError, "Request timed out after #{@timeout} seconds"
  rescue ServerError, TimeoutError => e
    if retry_count < MAX_RETRIES
      sleep(RETRY_DELAY * (2 ** retry_count)) # Exponential backoff
      make_request(endpoint, params, retry_count + 1)
    else
      raise
    end
  end

  def with_timeout(&block)
    Timeout.timeout(@timeout, &block)
  end

  def build_uri(endpoint, params)
    uri = URI("#{BASE_URL}#{endpoint}")
    uri.query = URI.encode_www_form(params)
    uri
  end

  def handle_response(response)
    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 401
      raise AuthenticationError, "Invalid API key"
    when 404
      raise NotFoundError, "City not found"
    when 429
      raise RateLimitError, "Rate limit exceeded. Please try again later."
    when 500..599
      raise ServerError, "Server error: #{response.code}"
    else
      raise APIError, "Unexpected response: #{response.code}"
    end
  rescue JSON::ParserError => e
    raise APIError, "Invalid JSON response: #{e.message}"
  end

  def parse_current_weather(data)
    {
      city: data['name'],
      temperature: data.dig('main', 'temp'),
      feels_like: data.dig('main', 'feels_like'),
      humidity: data.dig('main', 'humidity'),
      description: data.dig('weather', 0, 'description'),
      wind_speed: data.dig('wind', 'speed'),
      timestamp: Time.at(data['dt'])
    }
  rescue => e
    raise APIError, "Failed to parse weather data: #{e.message}"
  end

  def parse_forecast(data)
    data['list'].map do |item|
      {
        temperature: item.dig('main', 'temp'),
        description: item.dig('weather', 0, 'description'),
        timestamp: Time.at(item['dt'])
      }
    end
  rescue => e
    raise APIError, "Failed to parse forecast data: #{e.message}"
  end

  def validate_city!(city)
    if city.nil? || city.to_s.strip.empty?
      raise ArgumentError, "City name cannot be blank"
    end
  end

  def validate_units!(units)
    unless ['metric', 'imperial'].include?(units)
      raise ArgumentError, "Units must be 'metric' or 'imperial'"
    end
  end
end


# ============================================================================
# YOUR TESTS GO HERE
# ============================================================================
#
# Testing Approach Recommendations:
# ----------------------------------
#
# 1. STUBBING STRATEGY
#    You can stub at different levels:
#
#    a) Stub Net::HTTP.get_response (lowest level - most control)
#       - Allows you to test timeout handling
#       - Can simulate network failures
#       - Full control over response
#
#    b) Stub the make_request method (higher level)
#       - Simpler, but can't test timeout logic
#       - Good for testing business logic
#
#    c) Use a VCR-like recording/playback system
#       - Record real API responses once
#       - Replay in tests
#       - Best for integration tests
#
# 2. FIXTURE DATA
#    Create helper methods to generate realistic API responses:
#    - successful_weather_response(city: "London", temp: 20)
#    - error_response(code: 404, message: "city not found")
#    - malformed_json_response
#
# 3. TEST ORGANIZATION
#    Group tests logically:
#    - describe "#current_weather"
#      - context "with valid city"
#      - context "with invalid city"
#      - context "when API returns error"
#      - context "when request times out"
#      - context "with caching"
#
# 4. WHAT TO ASSERT
#    - Return values match expected structure
#    - Correct HTTP calls made (URL, params, headers)
#    - Errors raised for failure scenarios
#    - Retry logic triggered appropriately
#    - Cache behavior works correctly
#
# ============================================================================

# Test helper: Minimal test framework
def assert_equal(expected, actual, message = nil)
  if expected == actual
    print "."
  else
    puts "\n❌ FAILURE: #{message || 'Assertion failed'}"
    puts "  Expected: #{expected.inspect}"
    puts "  Actual:   #{actual.inspect}"
    caller.first(5).each { |line| puts "    #{line}" }
    exit 1
  end
end

def assert_raises(exception_class, message = nil)
  yield
  puts "\n❌ FAILURE: #{message || "Expected #{exception_class} to be raised"}"
  exit 1
rescue exception_class => e
  print "."
  e
rescue => e
  puts "\n❌ FAILURE: Expected #{exception_class}, got #{e.class}: #{e.message}"
  exit 1
end

def assert_true(condition, message = nil)
  if condition
    print "."
  else
    puts "\n❌ FAILURE: #{message || 'Expected true, got false'}"
    caller.first(5).each { |line| puts "    #{line}" }
    exit 1
  end
end

def assert_nil(value, message = nil)
  if value.nil?
    print "."
  else
    puts "\n❌ FAILURE: #{message || 'Expected nil'}"
    puts "  Actual: #{value.inspect}"
    exit 1
  end
end

# ============================================================================
# FIXTURE HELPERS
# ============================================================================
# Create these helpers to generate realistic API response data

def successful_weather_response(city: "London", temp: 20, description: "clear sky")
  {
    'name' => city,
    'main' => {
      'temp' => temp,
      'feels_like' => temp - 2,
      'humidity' => 65
    },
    'weather' => [
      { 'description' => description }
    ],
    'wind' => { 'speed' => 5.5 },
    'dt' => Time.now.to_i
  }
end

def successful_forecast_response(city: "London")
  {
    'list' => [
      {
        'main' => { 'temp' => 18 },
        'weather' => [{ 'description' => 'cloudy' }],
        'dt' => Time.now.to_i
      },
      {
        'main' => { 'temp' => 22 },
        'weather' => [{ 'description' => 'sunny' }],
        'dt' => Time.now.to_i + 3600
      }
    ]
  }
end

def http_response(code:, body:)
  response = Net::HTTPResponse.new('1.1', code.to_s, 'OK')
  response.instance_variable_set(:@body, body)
  response.instance_variable_set(:@read, true)
  response
end

# ============================================================================
# EXAMPLE TESTS - EXPAND THESE!
# ============================================================================

puts "Running WeatherService tests...\n"
puts "=" * 70

# ----------------------------------------------------------------------------
# INITIALIZATION TESTS
# ----------------------------------------------------------------------------
puts "\nTesting initialization..."

# Test: Valid initialization
service = WeatherService.new(api_key: "test_key_12345")
assert_equal "test_key_12345", service.api_key, "API key should be stored"

# Test: Rejects blank API key
error = assert_raises(ArgumentError, "Should reject nil API key") do
  WeatherService.new(api_key: nil)
end
assert_true error.message.include?("API key"), "Error message should mention API key"

# Test: Rejects empty API key
assert_raises(ArgumentError, "Should reject empty API key") do
  WeatherService.new(api_key: "")
end

def stub(object, method_name, response)
  original_method = object.method(method_name)

  object.define_singleton_method(method_name) do |*args|
    response
  end

  yield
  
  object.define_singleton_method(method_name, original_method)
end

# ----------------------------------------------------------------------------
# HAPPY PATH TESTS
# ----------------------------------------------------------------------------
puts "\nTesting happy path scenarios..."

# 1. HAPPY PATH
#    - Successfully fetch current weather

api_key = "abcd"
weather_service = WeatherService.new(api_key: api_key)

# Test: Successfully fetch current weather
fake_response = http_response(
  code: 200,
  body: successful_weather_response.to_json
)

stub(Net::HTTP, :get_response, fake_response) do
  result = weather_service.current_weather("London")
  assert_equal "London", result[:city]
  assert_equal 20, result[:temperature]
  assert_equal "clear sky", result[:description]
end

weather_service.clear_cache!

# ----------------------------------------------------------------------------
# ERROR HANDLING TESTS
# ----------------------------------------------------------------------------
puts "\nTesting error handling..."

# TODO: Test 401 Authentication Error

fake_response = http_response(
  code: 401,
  body: {}.to_json,
)

stub(Net::HTTP, :get_response, fake_response) do 
  assert_raises(WeatherService::AuthenticationError) do 
    weather_service.current_weather("Vancouver")
  end
end

# ----------------------------------------------------------------------------
# RETRY LOGIC TESTS
# ----------------------------------------------------------------------------
puts "\nTesting retry logic..."

# TODO: Test that 500 errors trigger retry
# TODO: Test that 404 errors do NOT trigger retry
# TODO: Test exponential backoff timing
# TODO: Test max retry limit
# TODO: Test that timeouts trigger retry

# Hint: Track call count to verify retries
# call_count = 0
# Net::HTTP.stub(:get_response) do
#   call_count += 1
#   # Return error on first N calls, success on last
# end

500_response = http_response(
  code: 500, 
  body: {}.to_json,
)
stub(Net::HTTP, :get_response, 500_response) do 

end


# ----------------------------------------------------------------------------
# CACHING TESTS
# ----------------------------------------------------------------------------
puts "\nTesting caching..."

# TODO: Test that responses are cached
# TODO: Test that cache keys are unique per query
# TODO: Test clear_cache! method
# TODO: Test that errors don't get cached

# ----------------------------------------------------------------------------
# INPUT VALIDATION TESTS
# ----------------------------------------------------------------------------
puts "\nTesting input validation..."

# TODO: Test nil city name
# TODO: Test empty city name
# TODO: Test invalid units
# TODO: Test whitespace-only city name

# ----------------------------------------------------------------------------
# ADVANCED: VCR-STYLE RECORDING
# ----------------------------------------------------------------------------
puts "\nTesting VCR pattern (optional)..."

# TODO: Implement a simple VCR-style recorder
# - First run: Make real API call, save response to file
# - Subsequent runs: Load response from file
# - This allows testing against real API structure without hitting it every time

# Example pattern:
# def vcr_playback(fixture_name, &block)
#   fixture_path = "fixtures/#{fixture_name}.json"
#   if File.exist?(fixture_path)
#     # Load and return recorded response
#   else
#     # Make real call, save response, return it
#   end
# end

puts "\n" + "=" * 70
puts "✅ All tests passed!"
puts "\nNext steps:"
puts "1. Implement all TODO test cases above"
puts "2. Add edge cases you can think of"
puts "3. Practice explaining your stubbing strategy out loud"
puts "4. Time yourself - can you write comprehensive tests in 60 minutes?"
puts "\nBonus challenges:"
puts "- Implement a VCR-style recording system from scratch"
puts "- Add parallel request testing (multiple cities at once)"
puts "- Test memory usage with large forecast responses"
puts "- Implement request/response logging and test it"
