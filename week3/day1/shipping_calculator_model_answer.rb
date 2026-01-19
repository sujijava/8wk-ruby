# =============================================================================
# Strategy Pattern - Shipping Calculator
# Model Answer
# =============================================================================

require "pry"

# =============================================================================
# STRATEGY INTERFACE
# =============================================================================

module ShippingStrategy
  def calculate(package)
    raise NotImplementedError, "#{self.class} must implement #calculate"
  end

  def estimate_delivery_days(distance)
    raise NotImplementedError, "#{self.class} must implement #estimate_delivery_days"
  end

  def name
    self.class.name.sub('Strategy', '')
  end
end

# =============================================================================
# CONCRETE STRATEGIES
# =============================================================================

class FedExStrategy
  include ShippingStrategy

  BASE_RATE = 12.00
  WEIGHT_RATE_PER_LB = 0.85
  DISTANCE_RATE_PER_MILE = 0.15
  HEAVY_PACKAGE_THRESHOLD = 50
  HEAVY_PACKAGE_SURCHARGE = 25.00
  DIMENSIONAL_DIVISOR = 139.0

  def calculate(package)
    weight = effective_weight(package)
    distance = package[:distance]

    total = BASE_RATE
    total += weight * WEIGHT_RATE_PER_LB
    total += distance * DISTANCE_RATE_PER_MILE
    total += HEAVY_PACKAGE_SURCHARGE if package[:weight] > HEAVY_PACKAGE_THRESHOLD

    total
  end

  def estimate_delivery_days(distance)
    distance < 500 ? 1 : 2
  end

  private

  def effective_weight(package)
    actual = package[:weight]
    dimensional = calculate_dimensional_weight(package[:dimensions])
    [actual, dimensional].max
  end

  def calculate_dimensional_weight(dimensions)
    return 0 if dimensions.nil? || dimensions.empty?

    length = dimensions[:length] || 0
    width = dimensions[:width] || 0
    height = dimensions[:height] || 0

    (length * width * height) / DIMENSIONAL_DIVISOR
  end
end


class UPSStrategy
  include ShippingStrategy

  BASE_RATE = 10.00
  WEIGHT_RATE_PER_LB = 0.75
  DISTANCE_RATE_PER_MILE = 0.12
  LIGHT_PACKAGE_THRESHOLD = 10
  LIGHT_PACKAGE_DISCOUNT = 0.90
  FUEL_SURCHARGE_RATE = 0.08

  def calculate(package)
    weight = package[:weight]
    distance = package[:distance]

    total = BASE_RATE
    total += weight * WEIGHT_RATE_PER_LB
    total += distance * DISTANCE_RATE_PER_MILE
    total *= LIGHT_PACKAGE_DISCOUNT if weight < LIGHT_PACKAGE_THRESHOLD
    total *= (1 + FUEL_SURCHARGE_RATE)

    total
  end

  def estimate_delivery_days(distance)
    distance < 500 ? 2 : 3
  end
end


class USPSStrategy
  include ShippingStrategy

  BASE_RATE = 7.00
  LIGHT_THRESHOLD = 5
  LIGHT_DISTANCE_RATE = 0.08
  HEAVY_WEIGHT_RATE = 0.60
  HEAVY_DISTANCE_RATE = 0.10
  WEEKEND_SURCHARGE = 5.00

  def calculate(package)
    weight = package[:weight]
    distance = package[:distance]

    total = if weight <= LIGHT_THRESHOLD
      BASE_RATE + (distance * LIGHT_DISTANCE_RATE)
    else
      BASE_RATE + (weight * HEAVY_WEIGHT_RATE) + (distance * HEAVY_DISTANCE_RATE)
    end

    total += WEEKEND_SURCHARGE if weekend?
    total
  end

  def estimate_delivery_days(distance)
    distance < 500 ? 3 : 5
  end

  private

  def weekend?
    Time.now.wday.then { |d| d == 0 || d == 6 }
  end
end


class DHLStrategy
  include ShippingStrategy

  BASE_RATE = 15.00
  WEIGHT_RATE_PER_LB = 0.95
  DISTANCE_RATE_PER_MILE = 0.18
  FREE_SHIPPING_WEIGHT_THRESHOLD = 100
  INTERNATIONAL_DISTANCE_THRESHOLD = 2000
  INTERNATIONAL_SURCHARGE = 30.00

  def calculate(package)
    weight = package[:weight]
    distance = package[:distance]

    return 0 if weight > FREE_SHIPPING_WEIGHT_THRESHOLD

    total = BASE_RATE
    total += weight * WEIGHT_RATE_PER_LB
    total += distance * DISTANCE_RATE_PER_MILE
    total += INTERNATIONAL_SURCHARGE if distance > INTERNATIONAL_DISTANCE_THRESHOLD

    total
  end

  def estimate_delivery_days(distance)
    distance < 500 ? 2 : 4
  end
end

# =============================================================================
# STRATEGY REGISTRY
# Single place to register all available carriers
# =============================================================================

class StrategyRegistry
  def initialize
    @strategies = {}
  end

  def register(name, strategy)
    @strategies[name.to_sym] = strategy
    self
  end

  def get(name)
    @strategies[name.to_sym]
  end

  def all
    @strategies
  end

  def names
    @strategies.keys
  end

  # Default registry with all carriers
  def self.default
    new
      .register(:fedex, FedExStrategy.new)
      .register(:ups, UPSStrategy.new)
      .register(:usps, USPSStrategy.new)
      .register(:dhl, DHLStrategy.new)
  end
end

# =============================================================================
# SHIPPING SERVICE
# Core domain logic - calculates costs, finds cheapest
# =============================================================================

class ShippingService
  def initialize(registry = StrategyRegistry.default)
    @registry = registry
  end

  def calculate(package, carrier)
    strategy = strategy_for(carrier)
    strategy.calculate(package)
  end

  def estimate_delivery(package, carrier)
    strategy = strategy_for(carrier)
    strategy.estimate_delivery_days(package[:distance])
  end

  def cheapest_carrier(package)
    rates = all_rates(package)
    rates.min_by { |_, cost| cost }&.first
  end

  def all_rates(package)
    @registry.all.each_with_object({}) do |(name, strategy), rates|
      rates[name] = strategy.calculate(package)
    rescue => e
      puts "Error calculating #{name}: #{e.message}"
    end
  end

  def carriers
    @registry.names
  end

  private

  def strategy_for(carrier)
    strategy = @registry.get(carrier)
    raise ArgumentError, "Unsupported carrier: #{carrier}" unless strategy
    strategy
  end
end

# =============================================================================
# CARRIER COMPARATOR
# Presentation logic for comparing carriers
# =============================================================================

class CarrierComparator
  def initialize(service = ShippingService.new)
    @service = service
  end

  def compare(package)
    print_header(package)

    rates = {}
    @service.carriers.each do |carrier|
      cost = @service.calculate(package, carrier)
      days = @service.estimate_delivery(package, carrier)
      rates[carrier] = cost

      printf("%-10s $%8.2f   (~%d days)\n", carrier.upcase, cost, days)
    rescue => e
      puts "#{carrier.upcase}: Error - #{e.message}"
    end

    print_cheapest(rates)
    rates
  end

  private

  def print_header(package)
    puts "\n" + "=" * 70
    puts "CARRIER COMPARISON"
    puts "=" * 70
    puts "Package: #{package[:weight]} lbs, #{package[:distance]} miles"
    puts "-" * 70
  end

  def print_cheapest(rates)
    puts "-" * 70
    cheapest = rates.min_by { |_, cost| cost }
    puts "Cheapest: #{cheapest[0].upcase} at $#{cheapest[1].round(2)}" if cheapest
    puts "=" * 70
  end
end

# =============================================================================
# SHIPMENT CREATOR
# Creates and stores shipments
# =============================================================================

class ShipmentCreator
  attr_reader :shipments

  def initialize(service = ShippingService.new)
    @service = service
    @shipments = []
  end

  def create(package, carrier)
    cost = @service.calculate(package, carrier)
    shipment = build_shipment(package, carrier, cost)
    @shipments << shipment

    puts "✓ Shipment created with #{carrier.upcase}: $#{cost.round(2)}"
    shipment
  end

  def create_cheapest(package)
    carrier = @service.cheapest_carrier(package)

    if carrier
      create(package, carrier)
    else
      puts "✗ Could not create shipment - no carriers available"
      nil
    end
  end

  private

  def build_shipment(package, carrier, cost)
    {
      id: generate_id,
      carrier: carrier,
      cost: cost,
      package: package,
      created_at: Time.now
    }
  end

  def generate_id
    "SHIP-#{Time.now.to_i}-#{rand(1000..9999)}"
  end
end

# =============================================================================
# REPORT GENERATOR
# Generates shipping reports
# =============================================================================

class ReportGenerator
  def generate(shipments)
    return puts "No shipments to report." if shipments.empty?

    print_header(shipments)
    print_by_carrier(shipments)
    print_total(shipments)
  end

  private

  def print_header(shipments)
    puts "\n" + "=" * 70
    puts "SHIPPING REPORT"
    puts "=" * 70
    puts "Total Shipments: #{shipments.count}"
    puts ""
  end

  def print_by_carrier(shipments)
    shipments.group_by { |s| s[:carrier] }.each do |carrier, group|
      total = group.sum { |s| s[:cost] }
      avg = total / group.count

      puts "#{carrier.upcase}:"
      puts "  Shipments: #{group.count}"
      puts "  Total Cost: $#{total.round(2)}"
      puts "  Avg Cost: $#{avg.round(2)}"
      puts ""
    end
  end

  def print_total(shipments)
    total = shipments.sum { |s| s[:cost] }
    puts "Overall Total: $#{total.round(2)}"
    puts "=" * 70
  end
end

# =============================================================================
# TEST
# =============================================================================

if __FILE__ == $0
  puts "Testing Shipping Calculator (Strategy Pattern)\n\n"

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

  # Shared service instance
  service = ShippingService.new
  comparator = CarrierComparator.new(service)
  creator = ShipmentCreator.new(service)

  # Compare carriers
  puts "\n--- Small Package ---"
  comparator.compare(small_package)

  puts "\n--- Medium Package ---"
  comparator.compare(medium_package)

  puts "\n--- Large Package ---"
  comparator.compare(large_package)

  # Create shipments
  puts "\n\nCreating shipments..."
  puts "-" * 70

  creator.create(small_package, :fedex)
  creator.create_cheapest(medium_package)
  creator.create(large_package, :ups)
  creator.create(small_package, :dhl)

  # Generate report
  ReportGenerator.new.generate(creator.shipments)

  # Demonstrate extensibility - add new carrier at runtime
  puts "\n\nAdding new carrier at runtime..."
  puts "-" * 70

  # Custom priority strategy - 50% more expensive, next day delivery
  class PriorityStrategy
    include ShippingStrategy

    def initialize(base_strategy)
      @base = base_strategy
    end

    def calculate(package)
      @base.calculate(package) * 1.5
    end

    def estimate_delivery_days(_distance)
      1
    end
  end

  # Add to existing registry
  registry = StrategyRegistry.default
  registry.register(:priority_fedex, PriorityStrategy.new(FedExStrategy.new))

  service_with_priority = ShippingService.new(registry)
  comparator_with_priority = CarrierComparator.new(service_with_priority)

  puts "\n--- With Priority Option ---"
  comparator_with_priority.compare(small_package)
end