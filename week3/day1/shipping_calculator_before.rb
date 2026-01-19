
# ==============================================================
require "json"

class ShippingCalculator
  attr_reader :shipments

  def initialize
    @shipments = []
  end

  # Calculate shipping cost based on carrier
  def calculate_shipping(package, carrier)
    weight = package[:weight]
    distance = package[:distance]
    dimensions = package[:dimensions] || {}

    case carrier.downcase
    when "fedex"
      # FedEx: Base rate + weight rate + distance rate
      # Premium service with faster delivery
      base_rate = 12.00
      weight_rate = weight * 0.85
      distance_rate = distance * 0.15

      # FedEx charges extra for oversized packages
      dimensional_weight = calculate_dimensional_weight(dimensions)
      if dimensional_weight > weight
        weight_rate = dimensional_weight * 0.85
      end

      total = base_rate + weight_rate + distance_rate

      # FedEx express surcharge for heavy packages
      if weight > 50
        total += 25.00
      end

      total

    when "ups"
      # UPS: Different pricing structure
      # Good balance of speed and cost
      base_rate = 10.00
      weight_rate = weight * 0.75
      distance_rate = distance * 0.12

      total = base_rate + weight_rate + distance_rate

      # UPS has volume discount for lighter packages
      if weight < 10
        total *= 0.90  # 10% discount
      end

      # UPS fuel surcharge
      total += (total * 0.08)

      total

    when "usps"
      # USPS: Cheapest but slowest
      # Great for light packages
      base_rate = 7.00

      if weight <= 5
        # Flat rate for light packages
        total = base_rate + (distance * 0.08)
      else
        # Higher rate for heavier packages
        weight_rate = weight * 0.60
        distance_rate = distance * 0.10
        total = base_rate + weight_rate + distance_rate
      end

      # USPS weekend surcharge
      if is_weekend?
        total += 5.00
      end

      total

    else
      raise "Unsupported carrier: #{carrier}"
    end
  end

  # Create a shipment with the cheapest option
  def create_cheapest_shipment(package)
    rates = {}

    ["fedex", "ups", "usps"].each do |carrier|
      begin
        rates[carrier] = calculate_shipping(package, carrier)
      rescue => e
        puts "Error calculating #{carrier}: #{e.message}"
      end
    end

    cheapest_carrier = rates.min_by { |carrier, rate| rate }&.first

    if cheapest_carrier
      cost = rates[cheapest_carrier]
      shipment = {
        id: generate_shipment_id,
        carrier: cheapest_carrier,
        cost: cost,
        package: package,
        created_at: Time.now
      }
      @shipments << shipment

      puts "✓ Shipment created with #{cheapest_carrier.upcase}: $#{cost.round(2)}"
      shipment
    else
      puts "✗ Could not create shipment - no carriers available"
      nil
    end
  end

  # Create shipment with specific carrier
  def create_shipment(package, carrier)
    cost = calculate_shipping(package, carrier)
    shipment = {
      id: generate_shipment_id,
      carrier: carrier,
      cost: cost,
      package: package,
      created_at: Time.now
    }
    @shipments << shipment

    puts "✓ Shipment created with #{carrier.upcase}: $#{cost.round(2)}"
    shipment
  end

  # Compare all carriers for a package
  def compare_carriers(package)
    puts "\n" + "=" * 70
    puts "CARRIER COMPARISON"
    puts "=" * 70
    puts "Package: #{package[:weight]} lbs, #{package[:distance]} miles"
    puts "-" * 70

    carriers = ["fedex", "ups", "usps"]
    rates = {}

    carriers.each do |carrier|
      begin
        cost = calculate_shipping(package, carrier)
        rates[carrier] = cost

        # Estimate delivery time
        delivery_days = estimate_delivery_time(package[:distance], carrier)

        printf("%-10s $%8.2f   (~%d days)\n", carrier.upcase, cost, delivery_days)
      rescue => e
        puts "#{carrier.upcase}: Error - #{e.message}"
      end
    end

    puts "-" * 70
    cheapest = rates.min_by { |_, cost| cost }
    if cheapest
      puts "Cheapest: #{cheapest[0].upcase} at $#{cheapest[1].round(2)}"
    end
    puts "=" * 70

    rates
  end

  # Generate shipping report
  def generate_report
    return if @shipments.empty?

    puts "\n" + "=" * 70
    puts "SHIPPING REPORT"
    puts "=" * 70
    puts "Total Shipments: #{@shipments.count}"
    puts ""

    by_carrier = @shipments.group_by { |s| s[:carrier] }
    by_carrier.each do |carrier, shipments|
      total_cost = shipments.sum { |s| s[:cost] }
      avg_cost = total_cost / shipments.count

      puts "#{carrier.upcase}:"
      puts "  Shipments: #{shipments.count}"
      puts "  Total Cost: $#{total_cost.round(2)}"
      puts "  Avg Cost: $#{avg_cost.round(2)}"
      puts ""
    end

    total_cost = @shipments.sum { |s| s[:cost] }
    puts "Overall Total: $#{total_cost.round(2)}"
    puts "=" * 70
  end

  private

  # Calculate dimensional weight (for oversized packages)
  def calculate_dimensional_weight(dimensions)
    return 0 if dimensions.empty?

    length = dimensions[:length] || 0
    width = dimensions[:width] || 0
    height = dimensions[:height] || 0

    # Dimensional weight formula: (L × W × H) / 139
    (length * width * height) / 139.0
  end

  def is_weekend?
    day = Time.now.wday
    day == 0 || day == 6  # Sunday = 0, Saturday = 6
  end

  def estimate_delivery_time(distance, carrier)
    case carrier.downcase
    when "fedex"
      distance < 500 ? 1 : 2
    when "ups"
      distance < 500 ? 2 : 3
    when "usps"
      distance < 500 ? 3 : 5
    else
      0
    end
  end

  def generate_shipment_id
    "SHIP-#{Time.now.to_i}-#{rand(1000..9999)}"
  end
end

# =============================================================================
# Test the system
# =============================================================================

if __FILE__ == $0
  calculator = ShippingCalculator.new

  puts "Testing Shipping Calculator...\n\n"

  # Sample packages
  small_package = {
    weight: 5,
    distance: 250,
    dimensions: { length: 10, width: 8, height: 6 }
  }

  medium_package = {
    weight: 25,
    distance: 1200,
    dimensions: { length: 20, width: 15, height: 12 }
  }

  large_package = {
    weight: 75,
    distance: 800,
    dimensions: { length: 36, width: 24, height: 24 }
  }

  # Compare carriers for each package
  puts "\n--- Small Package ---"
  calculator.compare_carriers(small_package)

  puts "\n--- Medium Package ---"
  calculator.compare_carriers(medium_package)

  puts "\n--- Large Package ---"
  calculator.compare_carriers(large_package)

  # Create some shipments
  puts "\n\nCreating shipments..."
  puts "-" * 70
  calculator.create_cheapest_shipment(small_package)
  calculator.create_cheapest_shipment(medium_package)
  calculator.create_shipment(large_package, "ups")
  calculator.create_shipment(small_package, "fedex")

  # Generate report
  calculator.generate_report
end

# =============================================================================
# YOUR TASK:
#
# This code has several problems:
# 1. The giant case statement makes adding new carriers difficult
# 2. Each carrier's logic is mixed together - hard to test individually
# 3. Violates Open/Closed Principle - must modify calculate_shipping for new carriers
# 4. Can't easily swap algorithms at runtime
# 5. Business logic is tightly coupled to the calculator class
#
# REQUIREMENTS:
# Refactor using the Strategy Pattern to:
# - Create separate strategy classes for each carrier (FedEx, UPS, USPS)
# - Each strategy encapsulates its own rate calculation algorithm
# - Make it easy to add new carriers (e.g., DHL) without modifying existing code
# - Allow runtime selection of shipping strategy
# - Keep all existing functionality working (comparisons, reports, etc.)
#
# BONUS CHALLENGES:
# 1. Add a new carrier: DHL
#    - Base rate: $15.00
#    - Weight rate: $0.95 per lb
#    - Distance rate: $0.18 per mile
#    - Free shipping for packages over 100 lbs
#    - International surcharge: +$30.00 if distance > 2000 miles
#
# 2. Implement a Priority strategy that costs 50% more but guarantees next-day delivery
#
# 3. Add validation to each strategy (e.g., USPS doesn't ship packages over 70 lbs)
#
# KEY CONCEPTS:
# - Strategy Pattern: Define a family of algorithms, encapsulate each one,
#   and make them interchangeable
# - Each strategy should implement a common interface
# - The context (ShippingCalculator) delegates to a strategy object
# - Strategies can be swapped at runtime
#
# HINTS:
# - Create a base Strategy class or module that defines the interface
# - Each carrier becomes a concrete strategy class
# - ShippingCalculator should accept and use strategy objects
# - Consider how to handle carrier-specific features (dimensional weight, surcharges)
# =============================================================================
