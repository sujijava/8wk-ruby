# Week 3 Day 2: Decorator Pattern - Coffee Ordering System
# Solution File

# YOUR SOLUTION HERE


require "pry"

class Coffee
  attr_accessor :description, :cost
  def initialize(description, cost)
    @description = description
    @cost = cost
  end
end


class CoffeeDecorator
  def cost
    raise NotImplementedError
  end

  def name
    self.class.name.gsub("Decorator", "")
  end
end

class Milk < CoffeeDecorator
  COST = 1
  def cost 
    COST
  end
end

class Sugar < CoffeeDecorator
  COST = 1
  def cost
    COST
  end
end

class Mocha < CoffeeDecorator
  COST = 1
  def cost
    COST
  end
end

class CoffeeBuilder
  ADD_ONS = {
    "milk": Milk.new,
    "sugar": Sugar.new,
    "mocha": Mocha.new,
  }

  def self.build(base, add_on)
    base_cost = base.cost
    add_on_cost = ADD_ONS[add_on.to_sym].cost
    
    base.cost = base_cost + add_on_cost
    base.description += add_on
    return base
  end
end


coffee = Coffee.new("Espresso", 1.99)
coffee = CoffeeBuilder.build(coffee, "milk")
puts coffee.cost
