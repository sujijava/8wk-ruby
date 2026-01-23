# Week 3 Day 5: Pricing Engine Solution
# Your solution goes here
require "pry"

class String
  def snake_case
    gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr(" -", "_")
      .downcase
  end
end

class Item 
  attr_reader :name, :price, :quantity, :category
  
  def initialize(name:, price:, quantity:, category:)
    @name = name
    @price = price
    @quantity = quantity
    @category = category
  end
end

class Order
  attr_reader :base_total, :items
  def initialize
    @items = []
    @base_total = 0
    @discount_total = 0
  end

  def add_item(item)
    @items << item
    @base_total += (item.price * item.quantity)
    @discount_total = base_total
  end

  def remove_item(item)
    @items.delete(item)
    @base_total -= (item.price * item.quantity)
    @discount_total = base_total
  end
end

# ===========================================================
class PricingEngine

  ''' 
  rules = [
  percentage_discount, 
  {min_items: 3, discount_percent: 10},
   ]
  '''

  def self.rule_generator(rules)
    generated_rules = []
    rules.each do |rule|
      generated_rules << RuleFactory.create_rule(rule[:rule_type], rule[:options])
    end
    generated_rules
  end

  def self.calculate(order, rules)
    break_down = {}
    applied_rules = []

    generated_rules = rule_generator(rules)
    generated_rules.each do |rule|
      applied_rules << rule
      new_price = rule.apply(order)
      break_down["after_#{rule.class.name.snake_case}".to_sym] = new_price
    end  

    return {
      original: order.discount_total,
      break_down: break_down,
      final_price: final_price,
      applied_rules: applied_rules,
    }
  end
end

# =============================================================

module PricingRule
  def apply(order)
    raise NotImplementedError
  end

  def eligible?(obj)
    raise NotImplementedError
  end

  def description
    raise NotImplementedError
  end
end

class NullPricingRule
  include PricingRule

  def apply(order)
    puts "NullPricingRule apply called"
  end

  def eligible?(obj)
    puts "NullPricingRule eligible? called"
  end

  def description
    puts "NullPricingRule description called"
  end
end

class PercentageDiscount
  include PricingRule

  def initialize(options)
    @min_items = options[:min_items]
    @discount_percent = options[:discount_percent]
  end
  
  def apply(order)
    new_order_price = 0

    order.items.each do |item|
      old_item_price = item.price   
      quantity = item.quantity

      if eligible?(item)
        # set price float -> important! 
        new_item_price = old_item_price * (( 100.0 - @discount_percent) / 100.0)
        new_order_price = new_order_price + (new_item_price * quantity)
      else
        new_order_price = new_order_price + (old_item_price * quantity)
      end
    end

    order.discount_price = new_order_price 
  end

  def eligible?(item)
    item.quantity >= @min_items
  end

  def description 
    "Percentage Discount: #{@discount_percent} off (#{@min_items} items)"
  end
end

class FixedDiscount
  include PricingRule

  def initialize(options)
    @amount = options[:amount]
    @min_order_amount = options[:min_order_amount]
  end
  
  def apply(order)
    if eligible?(order)
      order.discount_total = order.discount_total - @amount
    end
  end

  def eligible?(order)
    order.base_total >= @min_order_amount
  end

  def description 
    "Fixed Discount: #{@discount_percent} off (#{@min_order_amount}+ orders)"
  end
end

class CategoryDiscount
  include PricingRule

  def initialize(options)
    @category = options[:category]
    @percent = options[:percent]
  end
  
  def apply(order)
    new_order_price = 0

    order.items.each do |item|
      old_item_price = item.price   
      quantity = item.quantity

      if eligible?(item)
        # set price float -> important! 
        new_item_price = old_item_price * (( 100.0 - @percent) / 100.0)
        new_order_price = new_order_price + (new_item_price * quantity)
      else
        new_order_price = new_order_price + (old_item_price * quantity)
      end
    end

    order.discount_total = new_order_price
  end

  def eligible?(item)
    item.category == @category
  end

  def description 
    "Percentage Discount: #{@discount_percent} off (#{@min_items} items)"
  end
end

# ==================================================================

class RuleFactory
  RULES = {
    percentage_discount: PercentageDiscount,
    fixed_discount: FixedDiscount,
    category_discount: CategoryDiscount,
  }

  def self.create_rule(type, options)
    if RULES[type.to_sym]
      RULES[type.to_sym].new(options)
    else
      NullPricingRule.new
    end
  end
end

item = Item.new(name: "Laptop", price: 1000.0, quantity: 1, category: "Electronics")
item2 = Item.new(name: "Mouse", price: 25.0, quantity: 2, category: "Electronics")
item3 = Item.new(name: "Book", price: 15.0, quantity: 3, category: "Books")
# set price float -> important! 

order = Order.new
order.add_item(item)
order.add_item(item2)
order.add_item(item3)

rules = [
  { rule_type: :percentage_discount,
    options: {min_items: 3, discount_percent: 10.0}
  },
  {
    rule_type: :fixed_discount,
    options: {amount: 10.0, min_order_amount: 30.0}
  },
  {
    rule_type: :category_discount,
    options: {category: "Electronics", percent: 10.0}
  }
]

calculation = PricingEngine.calculate(order, rules)
puts calculation
puts order
puts rules