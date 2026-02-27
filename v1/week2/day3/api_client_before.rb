# Week 2, Day 3: Dependency Injection - Part 1
# Exercise: Refactor this API client to use dependency injection
#
# Current Problems:
# 1. HTTParty is hardcoded - impossible to test without hitting real APIs
# 2. Can't swap HTTP libraries (what if we want to use Faraday?)
# 3. No way to inject mock responses for testing
# 4. Tightly coupled to HTTParty's interface

require "httparty"
require "json"

# Simulated HTTParty responses for demonstration
# In reality, these would hit real APIs
module FakeHTTParty
  def self.get(url, options = {})
    case url
    when /weather/
      OpenStruct.new(
        code: 200,
        body: { temp: 72, condition: "Sunny", humidity: 45 }.to_json
      )
    when /geocode/
      OpenStruct.new(
        code: 200,
        body: { lat: 37.7749, lng: -122.4194, city: "San Francisco" }.to_json
      )
    when /exchange/
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
# PROBLEMATIC CODE - Hardcoded Dependencies
# =============================================================================

class WeatherClient
  API_BASE_URL = "https://api.weather.com"

  def get_forecast(city)
    # PROBLEM: HTTParty is hardcoded
    # - Can't test without hitting real API
    # - Can't swap to different HTTP library
    # - Can't inject mock responses
    url = "#{API_BASE_URL}/forecast?city=#{city}"
    response = FakeHTTParty.get(url)

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
    # PROBLEM: Duplicated HTTParty usage
    url = "#{API_BASE_URL}/current?city=#{city}"
    response = FakeHTTParty.get(url)

    if response.code == 200
      JSON.parse(response.body)
    else
      nil
    end
  end
end

class GeocodingClient
  API_BASE_URL = "https://api.maps.com"

  def geocode(address)
    # PROBLEM: Another hardcoded HTTParty call
    url = "#{API_BASE_URL}/geocode?address=#{address}"
    response = FakeHTTParty.get(url)

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
    # PROBLEM: More hardcoded dependencies
    url = "#{API_BASE_URL}/reverse?lat=#{lat}&lng=#{lng}"
    response = FakeHTTParty.get(url)

    if response.code == 200
      JSON.parse(response.body)
    else
      nil
    end
  end
end

class CurrencyExchangeClient
  API_BASE_URL = "https://api.exchange.com"

  def convert(amount, from_currency, to_currency)
    # PROBLEM: Hardcoded HTTParty again
    url = "#{API_BASE_URL}/exchange?from=#{from_currency}&to=#{to_currency}"
    response = FakeHTTParty.get(url)

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
    # PROBLEM: Yet another hardcoded call
    url = "#{API_BASE_URL}/rate?from=#{from_currency}&to=#{to_currency}"
    response = FakeHTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      data["rate"]
    else
      nil
    end
  end
end

# Composite service that uses multiple clients
class TravelPlannerService
  def get_destination_info(city)
    # PROBLEM: Creating clients with hardcoded dependencies
    weather_client = WeatherClient.new
    geocoding_client = GeocodingClient.new

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
    # PROBLEM: Can't inject a mock exchange client for testing
    exchange_client = CurrencyExchangeClient.new
    exchange_client.convert(amount, from_currency, to_currency)
  end
end

# =============================================================================
# Test the problematic code
# =============================================================================

if __FILE__ == $0
  puts "=" * 70
  puts "DEMONSTRATING THE PROBLEM: Hardcoded Dependencies"
  puts "=" * 70
  puts ""

  # These work, but are impossible to test without hitting real APIs
  puts "Weather Client (hardcoded HTTParty):"
  weather_client = WeatherClient.new
  forecast = weather_client.get_forecast("San Francisco")
  puts "  Forecast: #{forecast}"
  puts ""

  puts "Geocoding Client (hardcoded HTTParty):"
  geocoding_client = GeocodingClient.new
  location = geocoding_client.geocode("San Francisco, CA")
  puts "  Location: #{location}"
  puts ""

  puts "Currency Exchange Client (hardcoded HTTParty):"
  exchange_client = CurrencyExchangeClient.new
  conversion = exchange_client.convert(100, "USD", "EUR")
  puts "  Conversion: #{conversion}"
  puts ""

  puts "Travel Planner (composition of hardcoded clients):"
  planner = TravelPlannerService.new
  destination = planner.get_destination_info("San Francisco")
  puts "  Destination Info: #{destination}"
  puts ""

  puts "=" * 70
  puts "PROBLEMS:"
  puts "=" * 70
  puts "1. Cannot test without hitting real APIs"
  puts "2. Cannot swap HTTP libraries (locked into HTTParty)"
  puts "3. Cannot inject mock responses"
  puts "4. TravelPlannerService creates its own clients - not testable"
  puts "5. Every class is tightly coupled to HTTParty"
  puts ""
  puts "YOUR TASK:"
  puts "Refactor these classes to use dependency injection so they can be"
  puts "tested without external API calls and can use any HTTP library."
  puts "=" * 70
end

# =============================================================================
# YOUR TASK:
#
# Refactor this code to use dependency injection:
#
# 1. Inject the HTTP client instead of hardcoding HTTParty
# 2. Use default parameters so the code still works without explicit injection
# 3. Make TravelPlannerService accept injected clients
# 4. Create a mock HTTP client for testing
# 5. Demonstrate that your refactored code can be tested without real APIs
#
# Design questions to consider:
# - Should you inject the HTTP client in the constructor or as method parameters?
# - How can you provide defaults so existing code doesn't break?
# - Should there be a base class for all API clients?
# - How would you handle authentication tokens (another dependency)?
# =============================================================================
