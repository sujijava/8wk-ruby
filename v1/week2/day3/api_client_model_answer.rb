# Week 2, Day 3: Dependency Injection - MODEL ANSWER (A+)
# Demonstrates proper dependency injection for testability
#
# Key Design Decisions:
# 1. HTTP client is the external dependency - inject it
# 2. Default to FakeHTTParty for backward compatibility
# 3. API clients are stateless wrappers around HTTP calls
# 4. TravelPlannerService injects HTTP client, creates clients as needed
# 5. MockHTTPClient demonstrates testing without external APIs

require "json"
require "ostruct"

# =============================================================================
# SIMULATED HTTP CLIENT - Replaces real API calls
# =============================================================================

module FakeHTTParty
  def self.get(url, options = {})
    case url
    when /weather.*forecast/
      OpenStruct.new(
        code: 200,
        body: { temp: 72, condition: "Sunny", humidity: 45 }.to_json
      )
    when /weather.*current/
      OpenStruct.new(
        code: 200,
        body: { temp: 68, condition: "Cloudy", humidity: 50 }.to_json
      )
    when /maps.*geocode/
      OpenStruct.new(
        code: 200,
        body: { lat: 37.7749, lng: -122.4194, city: "San Francisco" }.to_json
      )
    when /maps.*reverse/
      OpenStruct.new(
        code: 200,
        body: { address: "1 Market St, San Francisco, CA", city: "San Francisco" }.to_json
      )
    when /exchange.*exchange/
      OpenStruct.new(
        code: 200,
        body: { from: "USD", to: "EUR", rate: 0.85 }.to_json
      )
    when /exchange.*rate/
      OpenStruct.new(
        code: 200,
        body: { from: "USD", to: "EUR", rate: 0.85 }.to_json
      )
    when /error/
      OpenStruct.new(code: 500, body: "Internal Server Error")
    else
      OpenStruct.new(code: 404, body: "Not Found")
    end
  end

  def self.post(url, options = {})
    OpenStruct.new(
      code: 201,
      body: { id: 123, status: "created" }.to_json
    )
  end
end

# =============================================================================
# MOCK HTTP CLIENT - For testing without any external dependencies
# =============================================================================

class MockHTTPClient
  attr_reader :requests

  def initialize(responses = {})
    @responses = responses
    @requests = []
  end

  def get(url, options = {})
    @requests << { method: :get, url: url, options: options }

    # Return configured response or default
    response = @responses[url] || default_response

    OpenStruct.new(response)
  end

  def post(url, options = {})
    @requests << { method: :post, url: url, options: options }

    response = @responses[url] || { code: 201, body: { success: true }.to_json }

    OpenStruct.new(response)
  end

  private

  def default_response
    {
      code: 200,
      body: { mock: true, data: "Mock response" }.to_json
    }
  end
end

# =============================================================================
# BASE API CLIENT - Optional: shared behavior for all API clients
# =============================================================================

class BaseAPIClient
  def initialize(http_client: FakeHTTParty)
    @http_client = http_client
  end

  protected

  def parse_json_response(response)
    return nil if response.code != 200
    JSON.parse(response.body)
  rescue JSON::ParserError
    nil
  end
end

# =============================================================================
# WEATHER CLIENT - Refactored with dependency injection
# =============================================================================

class WeatherClient < BaseAPIClient
  API_BASE_URL = "https://api.weather.com"

  def get_forecast(city)
    url = "#{API_BASE_URL}/forecast?city=#{city}"
    response = @http_client.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      {
        temperature: data["temp"],
        condition: data["condition"],
        humidity: data["humidity"]
      }
    else
      { error: "Failed to fetch weather data" }
    end
  end

  def get_current_weather(city)
    url = "#{API_BASE_URL}/current?city=#{city}"
    response = @http_client.get(url)

    if response.code == 200
      JSON.parse(response.body)
    else
      nil
    end
  end
end

# =============================================================================
# GEOCODING CLIENT - Refactored with dependency injection
# =============================================================================

class GeocodingClient < BaseAPIClient
  API_BASE_URL = "https://api.maps.com"

  def geocode(address)
    url = "#{API_BASE_URL}/geocode?address=#{address}"
    response = @http_client.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      {
        latitude: data["lat"],
        longitude: data["lng"],
        city: data["city"]
      }
    else
      { error: "Geocoding failed" }
    end
  end

  def reverse_geocode(lat, lng)
    url = "#{API_BASE_URL}/reverse?lat=#{lat}&lng=#{lng}"
    response = @http_client.get(url)

    if response.code == 200
      JSON.parse(response.body)
    else
      nil
    end
  end
end

# =============================================================================
# CURRENCY EXCHANGE CLIENT - Refactored with dependency injection
# =============================================================================

class CurrencyExchangeClient < BaseAPIClient
  API_BASE_URL = "https://api.exchange.com"

  def convert(amount, from_currency, to_currency)
    url = "#{API_BASE_URL}/exchange?from=#{from_currency}&to=#{to_currency}"
    response = @http_client.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      converted_amount = amount * data["rate"]
      {
        original_amount: amount,
        original_currency: from_currency,
        converted_amount: converted_amount.round(2),
        converted_currency: to_currency,
        rate: data["rate"]
      }
    else
      { error: "Exchange rate unavailable" }
    end
  end

  def get_rate(from_currency, to_currency)
    url = "#{API_BASE_URL}/rate?from=#{from_currency}&to=#{to_currency}"
    response = @http_client.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      data["rate"]
    else
      nil
    end
  end
end

# =============================================================================
# TRAVEL PLANNER SERVICE - Refactored with dependency injection
# =============================================================================

class TravelPlannerService
  def initialize(http_client: FakeHTTParty)
    @http_client = http_client
  end

  def get_destination_info(city)
    # Create clients with injected HTTP client
    # Only creates what's needed for this method
    weather_client = WeatherClient.new(http_client: @http_client)
    geocoding_client = GeocodingClient.new(http_client: @http_client)

    weather = weather_client.get_forecast(city)
    location = geocoding_client.geocode(city)

    {
      city: city,
      weather: weather,
      location: location,
      recommended: weather[:temperature] && weather[:temperature] > 60
    }
  end

  def calculate_trip_cost(amount, from_currency, to_currency)
    # Only creates exchange client (doesn't need weather/geocoding)
    exchange_client = CurrencyExchangeClient.new(http_client: @http_client)
    exchange_client.convert(amount, from_currency, to_currency)
  end
end

# =============================================================================
# DEMONSTRATION & TESTING
# =============================================================================

if __FILE__ == $0
  puts "=" * 80
  puts "DEPENDENCY INJECTION DEMONSTRATION"
  puts "=" * 80
  puts ""

  # -------------------------------------------------------------------------
  # 1. DEFAULT USAGE - Uses FakeHTTParty automatically
  # -------------------------------------------------------------------------
  puts "1. DEFAULT USAGE (backward compatible)"
  puts "-" * 80

  weather_client = WeatherClient.new
  forecast = weather_client.get_forecast("San Francisco")
  puts "Weather Forecast: #{forecast}"

  geocoding_client = GeocodingClient.new
  location = geocoding_client.geocode("San Francisco, CA")
  puts "Geocoded Location: #{location}"

  exchange_client = CurrencyExchangeClient.new
  conversion = exchange_client.convert(100, "USD", "EUR")
  puts "Currency Conversion: #{conversion}"

  planner = TravelPlannerService.new
  destination = planner.get_destination_info("San Francisco")
  puts "Destination Info: #{destination}"
  puts ""

  # -------------------------------------------------------------------------
  # 2. INJECTED MOCK CLIENT - Full control for testing
  # -------------------------------------------------------------------------
  puts "2. INJECTED MOCK CLIENT (testable)"
  puts "-" * 80

  # Configure mock responses
  mock_responses = {
    "https://api.weather.com/forecast?city=TestCity" => {
      code: 200,
      body: { temp: 85, condition: "Mocked Hot", humidity: 30 }.to_json
    },
    "https://api.maps.com/geocode?address=TestCity" => {
      code: 200,
      body: { lat: 40.0, lng: -120.0, city: "TestCity" }.to_json
    }
  }

  mock_http = MockHTTPClient.new(mock_responses)

  # Inject mock into clients
  weather_client = WeatherClient.new(http_client: mock_http)
  forecast = weather_client.get_forecast("TestCity")
  puts "Mocked Weather: #{forecast}"

  geocoding_client = GeocodingClient.new(http_client: mock_http)
  location = geocoding_client.geocode("TestCity")
  puts "Mocked Location: #{location}"

  # Verify mock was called correctly
  puts "Mock HTTP calls made: #{mock_http.requests.length}"
  mock_http.requests.each_with_index do |req, i|
    puts "  Call #{i + 1}: #{req[:method].to_s.upcase} #{req[:url]}"
  end
  puts ""

  # -------------------------------------------------------------------------
  # 3. TRAVEL PLANNER WITH MOCK - Composite service testing
  # -------------------------------------------------------------------------
  puts "3. TRAVEL PLANNER WITH MOCK"
  puts "-" * 80

  mock_http2 = MockHTTPClient.new(mock_responses)
  planner = TravelPlannerService.new(http_client: mock_http2)
  destination = planner.get_destination_info("TestCity")
  puts "Travel Plan: #{destination}"
  puts "HTTP calls made by planner: #{mock_http2.requests.length}"
  puts ""

  # -------------------------------------------------------------------------
  # 4. DEMONSTRATE SWAPPABLE HTTP CLIENTS
  # -------------------------------------------------------------------------
  puts "4. DIFFERENT HTTP CLIENT (flexibility)"
  puts "-" * 80

  # Create another mock with different behavior
  class AlternativeHTTPClient
    def get(url, options = {})
      OpenStruct.new(
        code: 200,
        body: { alternative: "This is a different HTTP client!" }.to_json
      )
    end
  end

  alt_http = AlternativeHTTPClient.new
  weather_client = WeatherClient.new(http_client: alt_http)
  result = weather_client.get_current_weather("Anywhere")
  puts "With alternative HTTP client: #{result}"
  puts ""

  # -------------------------------------------------------------------------
  # SUMMARY
  # -------------------------------------------------------------------------
  puts "=" * 80
  puts "DEPENDENCY INJECTION BENEFITS DEMONSTRATED"
  puts "=" * 80
  puts "✓ 1. Backward Compatible - Works without explicit injection"
  puts "✓ 2. Fully Testable - Can inject mock HTTP clients"
  puts "✓ 3. Flexible - Can swap HTTP client implementations"
  puts "✓ 4. Verifiable - Can inspect mock calls in tests"
  puts "✓ 5. Composable - Services can share the same HTTP client"
  puts "✓ 6. No External Dependencies - Tests don't hit real APIs"
  puts "=" * 80
  puts ""
  puts "KEY DESIGN DECISIONS:"
  puts "- HTTP client is the external dependency to inject"
  puts "- API clients are lightweight wrappers (stateless)"
  puts "- TravelPlannerService injects HTTP client, not clients themselves"
  puts "- Each method only creates the clients it needs (efficient)"
  puts "- Default parameters maintain backward compatibility"
  puts "=" * 80
end
