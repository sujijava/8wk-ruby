# ============================================================================
# Week 3 Day 2: Decorator Pattern
# ============================================================================
# Topic: Decorator Pattern
# Exercise: Implement a Coffee ordering system where you can add milk, sugar,
#           whip — price and description update dynamically
#
# The Decorator Pattern allows you to add new functionality to objects
# dynamically without altering their structure. It's particularly useful when
# you need to add responsibilities to individual objects, not entire classes.
#
# ============================================================================
# PROBLEM DESCRIPTION
# ============================================================================
#
# You're building a coffee shop ordering system. The core challenge is that
# customers can customize their coffee with multiple add-ons, and each add-on
# affects both the price and description.
#
# Requirements:
# 1. Start with base coffee types (Espresso, DarkRoast, Decaf, etc.)
#    - Each has its own base price and description
#
# 2. Implement add-ons/condiments (Milk, Sugar, Whip, Mocha, Soy, etc.)
#    - Each add-on has its own price
#    - Add-ons can be combined in any order
#    - The same add-on can be added multiple times
#
# 3. The system should dynamically calculate:
#    - Total cost: base coffee + all add-ons
#    - Description: base coffee + all add-ons listed
#
# 4. Use the Decorator Pattern (not simple composition or inheritance)
#
# ============================================================================
# DECORATOR PATTERN STRUCTURE (Pragmatic Ruby Approach)
# ============================================================================
#
# Component (Interface/Base Class)
#   ├─ Coffee (single class, data-driven - NOT a class per coffee type!)
#   └─ CoffeeDecorator (Base Decorator)
#       ├─ Milk
#       ├─ Sugar
#       ├─ Whip
#       └─ Mocha
#
# Key Points:
# - Coffee is a SINGLE class that takes type/name and price as data
#   (We don't make Espresso, DarkRoast classes - that's Java-style overkill!)
# - Decorators wrap a Coffee (or another decorator) and add behavior
# - Both Coffee and CoffeeDecorator respond to description and cost
# - Decorators delegate to the wrapped component
#
# ============================================================================
# EXAMPLE USAGE
# ============================================================================
#
# # Simple coffee
# coffee = Coffee.new("Espresso", 1.99)
# puts coffee.description  # => "Espresso"
# puts coffee.cost         # => 1.99
#
# # Coffee with one add-on
# coffee = Coffee.new("Espresso", 1.99)
# coffee = Milk.new(coffee)
# puts coffee.description  # => "Espresso, Milk"
# puts coffee.cost         # => 2.49  (1.99 + 0.50)
#
# # Coffee with multiple add-ons
# coffee = Coffee.new("Dark Roast", 1.49)
# coffee = Mocha.new(coffee)
# coffee = Mocha.new(coffee)  # double mocha!
# coffee = Whip.new(coffee)
# puts coffee.description  # => "Dark Roast, Mocha, Mocha, Whip"
# puts coffee.cost         # => 3.29  (1.49 + 0.70 + 0.70 + 0.40)
#
# ============================================================================
# INSTRUCTIONS
# ============================================================================
#
# 1. Create a Coffee class (the base component)
#    - Takes name and price in the constructor
#    - Implements description and cost methods
#    - This is ONE class that handles all coffee types (data-driven!)
#
# 2. Create a CoffeeDecorator base class
#    - Takes a coffee (or another decorator) in the constructor
#    - Delegates description and cost to the wrapped component
#    - Subclasses will add their own behavior on top
#
# 3. Create at least 4 concrete decorators (add-ons)
#    - Examples: Milk, Sugar, Whip, Mocha, Soy, Caramel
#    - Each should add to the cost and enhance the description
#    - Each decorator wraps another component (coffee or decorator)
#
# 4. Demonstrate your solution with various combinations
#
# Note: The point of the Decorator Pattern is the WRAPPING behavior, not
# creating a class hierarchy for coffee types. Keep it pragmatic!
#
# ============================================================================
# DISCUSSION POINTS (Think about these)
# ============================================================================
#
# 1. Why use ONE Coffee class instead of Espresso, DarkRoast classes?
#    - Coffee types are DATA, not behavior differences
#    - In Ruby, we prefer data-driven design over class hierarchies
#    - Easier to add new coffee types (just data, no new classes)
#    - This is the difference between Java-style and Ruby-style OOP!
#
# 2. Why is Decorator better than inheritance for add-ons?
#    - Inheritance would explode: EspressoWithMilk, EspressoWithMilkAndSugar...
#    - Can't add combinations at runtime
#    - Can't add the same decorator multiple times (double mocha!)
#
# 3. Why is Decorator better than simple boolean flags?
#    - What if Coffee had @milk, @sugar, @whip attributes?
#    - Need to update Coffee class every time you add a new add-on
#    - Can't handle multiples (double mocha, extra whip)
#    - Cost calculation gets messy with lots of conditionals
#
# 4. What are the tradeoffs of the Decorator pattern?
#    - More objects created (wrapping)
#    - Can be harder to debug (layers of wrapping)
#    - But: very flexible and follows Open/Closed Principle
#
# 5. How does this relate to middleware in Rack/Rails?
#    - Each middleware wraps the next, adding behavior
#    - Exactly the same pattern!
#
# 6. Other real-world uses in Ruby/Rails?
#    - Draper gem for view decorators
#    - SimpleDelegator in Ruby standard library
#    - ActionView helpers wrapping objects
#
# ============================================================================
# BONUS CHALLENGES
# ============================================================================
#
# 1. Add size options (Tall, Grande, Venti) that affect the base price
#
# 2. Implement a discount decorator that reduces price by a percentage
#
# 3. Add calorie tracking alongside price
#
# 4. Implement using Ruby's SimpleDelegator
#
# 5. Create a factory method: CoffeeShop.order(:espresso, add_ons: [:milk, :sugar])
#
# ============================================================================

# YOUR CODE HERE
