# Week 2, Day 1: Single Responsibility Principle
# Exercise: Refactor this OrderProcessor class that violates SRP
#
# This class has TOO MANY responsibilities:
# - Order validation
# - Payment processing
# - Email notifications
# - Inventory management
# - Shipping calculation
# - Order logging

require "pry"

class OrderValidator
  # OrderValidator.validate_for(order)
  def self.validate_for(order)
    validator = new(order)
    validator.validate

    return validator.errors.empty?
  end

  def initialize(order)
    @order = order
    @errors = Hash.new { |h, k| h[k] = [] }
  end

  attr_reader :errors

  def validate
    validate_items
    validate_customer_email
    validate_shipping_address
    validate_billing_address
  end

  private

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  def validate_items
    if @order[:items].nil? || @order[:items].empty?
      @errors[:items] << "Order must have at least one item"
    end
  end

  def validate_customer_email
    if @order[:customer_email].nil? || !valid_email?(@order[:customer_email])
      @errors[:customer_email] << "Invalid customer email"
    end
  end

  def validate_shipping_address
    if @order[:shipping_address].nil? || @order[:shipping_address][:zip].nil?
      @errors[:shipping_address] << "Invalid shipping address"
    end
  end

  def validate_billing_address
    if @order[:billing_address].nil?
      @errors[:billing_address] << "Billing address is required"
    end
  end
end

class PaymentProcessor

  def self.process_for(order)
    processor = new(order)
    processor.process

    return processor.errors.empty?
  end

  def self.calculate_shipping_for(order)
    processor = new(order)
    processor.calculate_shipping

    return processor.errors.empty?
  end

  def initialize(order)
    @order = order
    @errors = []
  end

  attr_reader :errors

  def process
    total = calculate_total

    begin
      # Simulate payment gateway call
      response = charge_credit_card(
        @order[:payment_method][:card_number],
        @order[:payment_method][:cvv],
        @order[:payment_method][:expiry],
        total
      )

      if response[:success]
        @order[:payment_id] = response[:transaction_id]
        @order[:payment_status] = "completed"
        true
      else
        @errors << "Payment failed: #{response[:error]}"
        false
      end
    rescue StandardError => e
      @errors << "Payment processing error: #{e.message}"
      false
    end
  end

  def calculate_shipping
    cost = calculate_shipping_cost
    @order[:shipping_cost] = cost
    @order[:estimated_delivery] = calculate_delivery_date
  end

  def calculate_total
    subtotal = @order[:items].sum { |item| item[:price] * item[:quantity] }
    tax = subtotal * 0.08
    shipping = calculate_shipping_cost
    subtotal + tax + shipping
  end
  
  private

  def charge_credit_card(card_number, cvv, expiry, amount)
    # Simulate payment gateway
    if card_number.length == 16 && cvv.length == 3
      { success: true, transaction_id: "TXN#{rand(100000)}" }
    else
      { success: false, error: "Invalid card details" }
    end
  end

  def calculate_shipping_cost
    zip = @order[:shipping_address][:zip]
    total_weight = @order[:items].sum { |item| item[:weight] * item[:quantity] }

    base_rate = 5.99
    weight_rate = total_weight * 0.5

    # Zone-based pricing
    if zip.start_with?("9")
      base_rate *= 1.5  # West coast premium
    elsif zip.start_with?("0")
      base_rate *= 1.3  # East coast premium
    end

    base_rate + weight_rate
  end

  def calculate_delivery_date
    zip = @order[:shipping_address][:zip]
    days = zip.start_with?("9") ? 5 : 3
    (Time.now + (days * 24 * 60 * 60)).strftime("%Y-%m-%d")
  end
end


class InventoryManager
  def self.update_inventory_for(order)
    inventory_manager = new(order)
    inventory_manager.update_inventory
    
    return inventory_manager.errors.empty?
  end

  def self.validate_inventory_for(order)
    inventory_manger = new(order)
    inventory_manger.validate_inventory

    return inventory_manger.errors.empty?
  end
  
  def initialize(order)
    @order = order
    @errors = {}    
  end

  attr_reader :errors

  def update_inventory
    @order[:items].each do |item|
      current_stock = get_current_stock(item[:product_id])
      new_stock = current_stock - item[:quantity]
      save_stock(item[:product_id], new_stock)

      if new_stock < 10
        send_low_stock_alert(item[:product_id], new_stock)
      end
    end
  end

  def validate_inventory
    @order[:items].each do |item|
      stock = get_current_stock(item[:product_id])
      if stock < item[:quantity]
        @errors << "Insufficient stock for #{item[:product_id]}"
      end
    end
  end

  private

  def get_current_stock(product_id)
    # Simulated database call
    inventory_db = {
      "PROD001" => 50,
      "PROD002" => 30,
      "PROD003" => 100
    }
    inventory_db[product_id] || 0
  end

  def save_stock(product_id, quantity)
    # Simulated database update
    puts "Updating inventory: #{product_id} -> #{quantity} units"
  end

  def send_low_stock_alert(product_id, quantity)
    # Simulated email to warehouse
    puts "LOW STOCK ALERT: #{product_id} only has #{quantity} units remaining"
  end
end

class Mailer


  def initialize()  
  end

  # Email notification responsibilities
  def send_confirmation_email(order)
    email_body = build_confirmation_email(order)
    send_email(
      to: order[:customer_email],
      subject: "Order Confirmation ##{order[:id]}",
      body: email_body
    )
  end

  def send_shipping_notification(order)
    email_body = build_shipping_email(order)
    send_email(
      to: order[:customer_email],
      subject: "Your order has shipped!",
      body: email_body
    )
  end

  private

  def build_confirmation_email(order)
    <<~EMAIL
      Thank you for your order!

      Order ID: #{order[:id]}
      Total: $#{PaymentProcessor.new(order).calculate_total}

      Items:
      #{order[:items].map { |i| "- #{i[:name]} x#{i[:quantity]}" }.join("\n")}

      Estimated delivery: #{order[:estimated_delivery]}
    EMAIL
  end

  def build_shipping_email(order)
    <<~EMAIL
      Great news! Your order has shipped.

      Tracking number: #{generate_tracking_number}
      Expected delivery: #{order[:estimated_delivery]}
    EMAIL
  end

  def send_email(to:, subject:, body:)
    # Simulated email service
    puts "Sending email to #{to}: #{subject}"
  end

  def generate_tracking_number
    "TRACK#{rand(1000000)}"
  end
end

class Logger

  def initialize(order)
    @order = order
  end

  # Logging and analytics responsibilities
  def log_order
    log_entry = {
      timestamp: Time.now,
      order_id: @order[:id],
      customer: @order[:customer_email],
      total: PaymentProcessor.new(@order).calculate_total,
      status: "completed"
    }

    write_to_log(log_entry)
  ende

  def update_analytics
    total = PaymentProcessor.new(@order).calculate_total

    # Track revenue
    update_daily_revenue(total)

    # Track popular products
    @order[:items].each do |item|
      increment_product_sales(item[:product_id], item[:quantity])
    end

    # Track customer metrics
    increment_customer_order_count(@order[:customer_email])
  end

  private
  def write_to_log(entry)
    # Simulated logging system
    puts "LOG: #{entry.inspect}"
  end

  def update_daily_revenue(amount)
    puts "Analytics: Adding $#{amount} to daily revenue"
  end

  def increment_product_sales(product_id, quantity)
    puts "Analytics: Product #{product_id} sold #{quantity} units"
  end

  def increment_customer_order_count(email)
    puts "Analytics: Customer #{email} order count +1"
  end
end

# ================================================================================================
class OrderProcessor
  attr_reader :order, :errors

  def initialize(order)
    @order = order
    @errors = []
  end

  def process
    return false unless OrderValidator.validate_for(@order)
    return false unless InventoryManager.validate_inventory_for(@order)
    return false unless PaymentProcessor.process_for(@order)

    InventoryManager.update_inventory_for(@order)
    PaymentProcessor.calculate_shipping_for(@order)
    Mailer.new().send_confirmation_email(@order)
    Mailer.new().send_shipping_notification(@order)
    Logger.new(@order).log_order
    Logger.new(@order).update_analytics

    true
  end
end

# Test the class
if __FILE__ == $0
  order = {
    id: "ORD123",
    customer_email: "customer@example.com",
    items: [
      { product_id: "PROD001", name: "Widget", price: 29.99, quantity: 2, weight: 1.5 },
      { product_id: "PROD002", name: "Gadget", price: 49.99, quantity: 1, weight: 2.0 }
    ],
    shipping_address: {
      street: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip: "94102"
    },
    billing_address: {
      street: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip: "94102"
    },
    payment_method: {
      card_number: "1234567890123456",
      cvv: "123",
      expiry: "12/25"
    }
  }

  processor = OrderProcessor.new(order)
  if processor.process
    puts "\n✓ Order processed successfully!"
  else
    puts "\n✗ Order processing failed:"
    processor.errors.each { |error| puts "  - #{error}" }
  end
end
