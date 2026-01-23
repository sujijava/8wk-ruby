# ============================================================================
# SOLUTION: Coffee Ordering System using Decorator Pattern
# ============================================================================

# ----------------------------------------------------------------------------
# Base Component: Coffee
# ----------------------------------------------------------------------------
# Design Decision: Single class with data, not a class-per-coffee-type hierarchy.
# Why? Coffee types differ only in name/price (data), not behavior.
# This is idiomatic Ruby - we favor composition and data over inheritance.

class Coffee
  attr_reader :name, :base_price

  def initialize(name, base_price)
    @name = name
    @base_price = base_price
  end

  def description
    name
  end

  def cost
    base_price
  end
end

# ----------------------------------------------------------------------------
# Base Decorator: CoffeeDecorator
# ----------------------------------------------------------------------------
# This establishes the decorator contract:
# 1. Wraps a component (coffee or another decorator)
# 2. Delegates to wrapped component
# 3. Subclasses extend behavior while preserving the interface
#
# Key insight: Both Coffee and CoffeeDecorator respond to `description` and `cost`.
# This is the Liskov Substitution Principle in action - decorators are
# substitutable for the components they wrap.

class CoffeeDecorator
  attr_reader :coffee

  def initialize(coffee)
    @coffee = coffee
  end

  # Default delegation - subclasses override to add behavior
  def description
    coffee.description
  end

  def cost
    coffee.cost
  end

  # Useful for debugging the decoration chain
  def inspect
    "#<#{self.class.name} wrapping: #{coffee.inspect}>"
  end
end

# ----------------------------------------------------------------------------
# Concrete Decorators: Add-ons
# ----------------------------------------------------------------------------
# Each decorator:
# 1. Inherits from CoffeeDecorator (gets wrapping behavior)
# 2. Calls super to delegate to wrapped component
# 3. Adds its own contribution to description/cost
#
# Pattern: description = wrapped.description + ", #{addon_name}"
#          cost = wrapped.cost + addon_price

class Milk < CoffeeDecorator
  PRICE = 0.50

  def description
    "#{coffee.description}, Milk"
  end

  def cost
    coffee.cost + PRICE
  end
end

class Sugar < CoffeeDecorator
  PRICE = 0.20

  def description
    "#{coffee.description}, Sugar"
  end

  def cost
    coffee.cost + PRICE
  end
end

class Whip < CoffeeDecorator
  PRICE = 0.40

  def description
    "#{coffee.description}, Whip"
  end

  def cost
    coffee.cost + PRICE
  end
end

class Mocha < CoffeeDecorator
  PRICE = 0.70

  def description
    "#{coffee.description}, Mocha"
  end

  def cost
    coffee.cost + PRICE
  end
end

class Soy < CoffeeDecorator
  PRICE = 0.60

  def description
    "#{coffee.description}, Soy"
  end

  def cost
    coffee.cost + PRICE
  end
end

class Caramel < CoffeeDecorator
  PRICE = 0.55

  def description
    "#{coffee.description}, Caramel"
  end

  def cost
    coffee.cost + PRICE
  end
end

# ============================================================================
# BONUS #1: Size Decorator (affects base price with multiplier)
# ============================================================================
# Interesting variation: this decorator modifies the cost multiplicatively,
# not additively. Shows decorator flexibility.

class SizeDecorator < CoffeeDecorator
  SIZES = {
    tall: { label: "Tall", multiplier: 1.0 },
    grande: { label: "Grande", multiplier: 1.3 },
    venti: { label: "Venti", multiplier: 1.6 }
  }.freeze

  def initialize(coffee, size = :tall)
    super(coffee)
    @size = SIZES.fetch(size) { SIZES[:tall] }
  end

  def description
    "#{@size[:label]} #{coffee.description}"
  end

  def cost
    (coffee.cost * @size[:multiplier]).round(2)
  end
end

# ============================================================================
# BONUS #2: Discount Decorator
# ============================================================================
# Another multiplicative decorator. Note: order matters!
# Discount applied after add-ons vs before gives different results.

class Discount < CoffeeDecorator
  def initialize(coffee, percent:)
    super(coffee)
    @percent = percent
  end

  def description
    "#{coffee.description} (#{@percent}% off)"
  end

  def cost
    (coffee.cost * (1 - @percent / 100.0)).round(2)
  end
end

# ============================================================================
# BONUS #3: Calorie Tracking
# ============================================================================
# Extend the interface to track calories alongside price.
# This shows how decorators can enhance multiple dimensions.

module CalorieTracking
  CALORIES = {
    "Coffee" => 5,
    "Milk" => 50,
    "Sugar" => 20,
    "Whip" => 100,
    "Mocha" => 90,
    "Soy" => 30,
    "Caramel" => 60
  }.freeze
end

class CalorieAwareCoffee < Coffee
  include CalorieTracking

  def calories
    CALORIES["Coffee"]
  end
end

class CalorieAwareDecorator < CoffeeDecorator
  include CalorieTracking

  def calories
    coffee.calories + self.class::ADDON_CALORIES
  end
end

class CalorieAwareMilk < CalorieAwareDecorator
  ADDON_CALORIES = 50
  PRICE = 0.50

  def description
    "#{coffee.description}, Milk"
  end

  def cost
    coffee.cost + PRICE
  end
end

# ============================================================================
# BONUS #5: Factory Method for Clean API
# ============================================================================
# Provides a nice DSL while still using decorators under the hood.
# This is the "make it easy to use correctly" principle.

module CoffeeShop
  COFFEES = {
    espresso: { name: "Espresso", price: 1.99 },
    dark_roast: { name: "Dark Roast", price: 1.49 },
    house_blend: { name: "House Blend", price: 0.99 },
    decaf: { name: "Decaf", price: 1.29 }
  }.freeze

  ADDONS = {
    milk: Milk,
    sugar: Sugar,
    whip: Whip,
    mocha: Mocha,
    soy: Soy,
    caramel: Caramel
  }.freeze

  def self.order(coffee_type, add_ons: [], size: nil, discount: nil)
    config = COFFEES.fetch(coffee_type) do
      raise ArgumentError, "Unknown coffee: #{coffee_type}. Available: #{COFFEES.keys.join(', ')}"
    end

    coffee = Coffee.new(config[:name], config[:price])

    # Apply size first (affects base price)
    coffee = SizeDecorator.new(coffee, size) if size

    # Apply each add-on (can repeat)
    add_ons.each do |addon|
      decorator_class = ADDONS.fetch(addon) do
        raise ArgumentError, "Unknown add-on: #{addon}. Available: #{ADDONS.keys.join(', ')}"
      end
      coffee = decorator_class.new(coffee)
    end

    # Apply discount last (on total)
    coffee = Discount.new(coffee, percent: discount) if discount

    coffee
  end

  def self.menu
    puts "=" * 50
    puts "COFFEE MENU"
    puts "=" * 50
    puts "\nBase Coffees:"
    COFFEES.each do |key, config|
      puts "  #{key.to_s.ljust(15)} $#{'%.2f' % config[:price]}"
    end
    puts "\nAdd-ons:"
    ADDONS.each do |key, klass|
      puts "  #{key.to_s.ljust(15)} +$#{'%.2f' % klass::PRICE}"
    end
    puts "\nSizes: tall (1x), grande (1.3x), venti (1.6x)"
    puts "=" * 50
  end
end

# ============================================================================
# DEMONSTRATION
# ============================================================================

def print_order(coffee)
  puts "  #{coffee.description}"
  puts "  Total: $#{'%.2f' % coffee.cost}"
  puts
end

puts "=" * 60
puts "DECORATOR PATTERN DEMONSTRATION"
puts "=" * 60

puts "\n1. SIMPLE COFFEE (no decorators)"
puts "-" * 40
coffee = Coffee.new("Espresso", 1.99)
print_order(coffee)

puts "2. SINGLE DECORATOR"
puts "-" * 40
coffee = Coffee.new("Espresso", 1.99)
coffee = Milk.new(coffee)
print_order(coffee)

puts "3. MULTIPLE DECORATORS"
puts "-" * 40
coffee = Coffee.new("Dark Roast", 1.49)
coffee = Mocha.new(coffee)
coffee = Mocha.new(coffee)  # Double mocha!
coffee = Whip.new(coffee)
print_order(coffee)

puts "4. STACKING ORDER MATTERS"
puts "-" * 40
coffee = Coffee.new("House Blend", 0.99)
coffee = Milk.new(coffee)
coffee = Sugar.new(coffee)
coffee = Sugar.new(coffee)  # Extra sweet
coffee = Caramel.new(coffee)
print_order(coffee)

puts "5. SIZE DECORATOR (BONUS #1)"
puts "-" * 40
coffee = Coffee.new("Espresso", 1.99)
coffee = SizeDecorator.new(coffee, :venti)
coffee = Milk.new(coffee)
print_order(coffee)

puts "6. DISCOUNT DECORATOR (BONUS #2)"
puts "-" * 40
coffee = Coffee.new("Dark Roast", 1.49)
coffee = Mocha.new(coffee)
coffee = Whip.new(coffee)
coffee = Discount.new(coffee, percent: 15)
print_order(coffee)

puts "7. FACTORY METHOD API (BONUS #5)"
puts "-" * 40
CoffeeShop.menu
puts

order = CoffeeShop.order(:espresso, add_ons: [:milk, :sugar])
puts "Simple order:"
print_order(order)

order = CoffeeShop.order(:dark_roast, size: :grande, add_ons: [:mocha, :mocha, :whip])
puts "Complex order:"
print_order(order)

order = CoffeeShop.order(:house_blend, size: :venti, add_ons: [:soy, :caramel], discount: 10)
puts "Order with discount:"
print_order(order)

# 1. CORRECT PATTERN IMPLEMENTATION
#    - Clear separation: Component (Coffee) vs Decorator (CoffeeDecorator)
#    - Decorators properly delegate to wrapped component
#    - Same interface throughout the chain (description, cost)
#
# 2. IDIOMATIC RUBY
#    - Data-driven Coffee class (not Java-style class hierarchy)
#    - Constants for prices (PRICE, SIZES)
#    - Module for shared constants (CalorieTracking)
#    - Clean factory method with keyword arguments
#
# 3. DEMONSTRATES UNDERSTANDING OF TRADE-OFFS
#    - Explained why one Coffee class vs many
#    - Noted that order of decorators can matter (discount example)
#    - Showed both direct usage and factory method patterns
#
# 4. EXTENSIBILITY (Open/Closed Principle)
#    - Adding new add-ons: just create new decorator class
#    - Adding new coffees: just add data to COFFEES hash
#    - No modification to existing classes needed
#
# 5. PRODUCTION CONSIDERATIONS
#    - Proper rounding for currency (round(2))
#    - Error handling in factory (ArgumentError for unknown types)
#    - Useful inspect method for debugging
#
# 6. BONUS CHALLENGES SHOW DEPTH
#    - Multiplicative decorators (size, discount)
#    - Extended interface (calories)
#    - Clean API via factory method
#
# ============================================================================