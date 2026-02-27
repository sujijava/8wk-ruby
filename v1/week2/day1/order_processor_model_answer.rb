# Week 2, Day 1: Single Responsibility Principle - MODEL ANSWER
# This is an A+ solution that demonstrates proper SRP implementation
#
# Key improvements from the original:
# 1. Fixed syntax errors (ende -> end, inventory_manger typo)
# 2. Extracted ShippingCalculator from PaymentProcessor (SRP violation fix)
# 3. Created OrderCalculator for consistent total calculations (removes duplication)
# 4. Standardized error handling (all classes use arrays)
# 5. Split Logger into OrderLogger and AnalyticsTracker (SRP violation fix)
# 6. Optimized object instantiation in OrderProcessor
# 7. Added clear layer separation with comments
# 8. Improved encapsulation and cohesion

require "pry"

# ================================================================================================
# VALIDATION LAYER - Responsible for validating order data
# ================================================================================================

class OrderValidator
  def self.validate_for(order)
    validator = new(order)
    validator.validate
    validator.errors.empty?
  end

  def initialize(order)
    @order = order
    @errors = []
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
      @errors << "Order must have at least one item"
    end
  end

  def validate_customer_email
    if @order[:customer_email].nil? || !valid_email?(@order[:customer_email])
      @errors << "Invalid customer email"
    end
  end

  def validate_shipping_address
    if @order[:shipping_address].nil? || @order[:shipping_address][:zip].nil?
      @errors << "Invalid shipping address"
    end
  end

  def validate_billing_address
    if @order[:billing_address].nil?
      @errors << "Billing address is required"
    end
  end
end

# ================================================================================================
# CALCULATION LAYER - Responsible for financial calculations
# ================================================================================================

class OrderCalculator
  TAX_RATE = 0.08

  def self.calculate_total_for(order)
    calculator = new(order)
    calculator.calculate_total
  end

  def self.calculate_subtotal_for(order)
    calculator = new(order)
    calculator.calculate_subtotal
  end

  def initialize(order)
    @order = order
  end

  def calculate_subtotal
    @order[:items].sum { |item| item[:price] * item[:quantity] }
  end

  def calculate_tax
    calculate_subtotal * TAX_RATE
  end

  def calculate_total
    subtotal = calculate_subtotal
    tax = calculate_tax
    shipping = ShippingCalculator.calculate_cost_for(@order)
    subtotal + tax + shipping
  end
end

# ================================================================================================
# SHIPPING LAYER - Responsible for shipping calculations
# ================================================================================================

class ShippingCalculator
  BASE_RATE = 5.99
  WEIGHT_RATE_PER_UNIT = 0.5
  WEST_COAST_MULTIPLIER = 1.5
  EAST_COAST_MULTIPLIER = 1.3

  def self.calculate_cost_for(order)
    calculator = new(order)
    calculator.calculate_cost
  end

  def self.calculate_delivery_date_for(order)
    calculator = new(order)
    calculator.calculate_delivery_date
  end

  def self.calculate_shipping_details_for(order)
    calculator = new(order)
    {
      cost: calculator.calculate_cost,
      estimated_delivery: calculator.calculate_delivery_date
    }
  end

  def initialize(order)
    @order = order
  end

  def calculate_cost
    zip = @order[:shipping_address][:zip]
    total_weight = calculate_total_weight
    base_rate = apply_zone_multiplier(BASE_RATE, zip)
    weight_charge = total_weight * WEIGHT_RATE_PER_UNIT
    base_rate + weight_charge
  end

  def calculate_delivery_date
    zip = @order[:shipping_address][:zip]
    days = zip.start_with?("9") ? 5 : 3
    (Time.now + (days * 24 * 60 * 60)).strftime("%Y-%m-%d")
  end

  private

  def calculate_total_weight
    @order[:items].sum { |item| item[:weight] * item[:quantity] }
  end

  def apply_zone_multiplier(base_rate, zip)
    if zip.start_with?("9")
      base_rate * WEST_COAST_MULTIPLIER
    elsif zip.start_with?("0")
      base_rate * EAST_COAST_MULTIPLIER
    else
      base_rate
    end
  end
end

# ================================================================================================
# PAYMENT LAYER - Responsible ONLY for payment processing
# ================================================================================================

class PaymentProcessor
  def self.process_for(order)
    processor = new(order)
    processor.process
    processor.errors.empty?
  end

  def initialize(order)
    @order = order
    @errors = []
  end

  attr_reader :errors

  def process
    total = OrderCalculator.calculate_total_for(@order)

    begin
      response = charge_credit_card(
        @order[:payment_method][:card_number],
        @order[:payment_method][:cvv],
        @order[:payment_method][:expiry],
        total
      )

      if response[:success]
        @order[:payment_id] = response[:transaction_id]
        @order[:payment_status] = "completed"
        @order[:total] = total
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

  private

  def charge_credit_card(card_number, cvv, expiry, amount)
    # Simulate payment gateway
    if card_number.length == 16 && cvv.length == 3
      { success: true, transaction_id: "TXN#{rand(100000)}" }
    else
      { success: false, error: "Invalid card details" }
    end
  end
end

# ================================================================================================
# INVENTORY LAYER - Responsible for stock management
# ================================================================================================

class InventoryManager
  LOW_STOCK_THRESHOLD = 10

  def self.update_inventory_for(order)
    manager = new(order)
    manager.update_inventory
    manager.errors.empty?
  end

  def self.validate_inventory_for(order)
    manager = new(order)
    manager.validate_inventory
    manager.errors.empty?
  end

  def initialize(order)
    @order = order
    @errors = []
  end

  attr_reader :errors

  def validate_inventory
    @order[:items].each do |item|
      stock = get_current_stock(item[:product_id])
      if stock < item[:quantity]
        @errors << "Insufficient stock for #{item[:product_id]}"
      end
    end
  end

  def update_inventory
    @order[:items].each do |item|
      current_stock = get_current_stock(item[:product_id])
      new_stock = current_stock - item[:quantity]
      save_stock(item[:product_id], new_stock)

      if new_stock < LOW_STOCK_THRESHOLD
        send_low_stock_alert(item[:product_id], new_stock)
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

# ================================================================================================
# NOTIFICATION LAYER - Responsible ONLY for sending emails
# ================================================================================================

class Mailer
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
    total = order[:total] || OrderCalculator.calculate_total_for(order)
    estimated_delivery = order[:estimated_delivery] || ShippingCalculator.calculate_delivery_date_for(order)

    <<~EMAIL
      Thank you for your order!

      Order ID: #{order[:id]}
      Total: $#{total.round(2)}

      Items:
      #{order[:items].map { |i| "- #{i[:name]} x#{i[:quantity]}" }.join("\n")}

      Estimated delivery: #{estimated_delivery}
    EMAIL
  end

  def build_shipping_email(order)
    estimated_delivery = order[:estimated_delivery] || ShippingCalculator.calculate_delivery_date_for(order)

    <<~EMAIL
      Great news! Your order has shipped.

      Tracking number: #{generate_tracking_number}
      Expected delivery: #{estimated_delivery}
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

# ================================================================================================
# LOGGING LAYER - Responsible ONLY for logging order events
# ================================================================================================

class OrderLogger
  def initialize(order)
    @order = order
  end

  def log_order
    log_entry = {
      timestamp: Time.now,
      order_id: @order[:id],
      customer: @order[:customer_email],
      total: @order[:total] || OrderCalculator.calculate_total_for(@order),
      status: "completed"
    }

    write_to_log(log_entry)
  end

  private

  def write_to_log(entry)
    # Simulated logging system
    puts "LOG: #{entry.inspect}"
  end
end

# ================================================================================================
# ANALYTICS LAYER - Responsible ONLY for tracking business metrics
# ================================================================================================

class AnalyticsTracker
  def initialize(order)
    @order = order
  end

  def track_order
    total = @order[:total] || OrderCalculator.calculate_total_for(@order)

    update_daily_revenue(total)
    track_product_sales
    track_customer_metrics
  end

  private

  def update_daily_revenue(amount)
    puts "Analytics: Adding $#{amount.round(2)} to daily revenue"
  end

  def track_product_sales
    @order[:items].each do |item|
      increment_product_sales(item[:product_id], item[:quantity])
    end
  end

  def track_customer_metrics
    increment_customer_order_count(@order[:customer_email])
  end

  def increment_product_sales(product_id, quantity)
    puts "Analytics: Product #{product_id} sold #{quantity} units"
  end

  def increment_customer_order_count(email)
    puts "Analytics: Customer #{email} order count +1"
  end
end

# ================================================================================================
# ORCHESTRATION LAYER - Responsible ONLY for coordinating the order flow
# ================================================================================================

class OrderProcessor
  attr_reader :order, :errors

  def initialize(order)
    @order = order
    @errors = []
  end

  def process
    return false unless validate_order
    return false unless process_payment

    finalize_order
    notify_customer
    record_order

    true
  end

  private

  def validate_order
    return false unless OrderValidator.validate_for(@order)
    return false unless InventoryManager.validate_inventory_for(@order)
    true
  end

  def process_payment
    PaymentProcessor.process_for(@order)
  end

  def finalize_order
    # Calculate and store shipping details
    shipping_details = ShippingCalculator.calculate_shipping_details_for(@order)
    @order[:shipping_cost] = shipping_details[:cost]
    @order[:estimated_delivery] = shipping_details[:estimated_delivery]

    # Update inventory
    InventoryManager.update_inventory_for(@order)
  end

  def notify_customer
    mailer = Mailer.new
    mailer.send_confirmation_email(@order)
    mailer.send_shipping_notification(@order)
  end

  def record_order
    OrderLogger.new(@order).log_order
    AnalyticsTracker.new(@order).track_order
  end
end

# ================================================================================================
# TEST EXECUTION
# ================================================================================================

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
    puts "Total: $#{order[:total].round(2)}"
    puts "Shipping: $#{order[:shipping_cost].round(2)}"
    puts "Estimated delivery: #{order[:estimated_delivery]}"
  else
    puts "\n✗ Order processing failed:"
    processor.errors.each { |error| puts "  - #{error}" }
  end
end
