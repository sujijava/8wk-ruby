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

class OrderProcessor
  attr_reader :order, :errors

  def initialize(order)
    @order = order
    @errors = []
  end

  def process
    return false unless validate_order
    return false unless validate_inventory
    return false unless process_payment

    update_inventory
    calculate_shipping
    send_confirmation_email
    send_shipping_notification
    log_order
    update_analytics

    true
  end

  private

  # Validation responsibilities
  def validate_order
    if order[:items].nil? || order[:items].empty?
      @errors << "Order must have at least one item"
      return false
    end

    if order[:customer_email].nil? || !valid_email?(order[:customer_email])
      @errors << "Invalid customer email"
      return false
    end

    if order[:shipping_address].nil? || order[:shipping_address][:zip].nil?
      @errors << "Invalid shipping address"
      return false
    end

    if order[:billing_address].nil?
      @errors << "Billing address is required"
      return false
    end

    true
  end

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end

  def validate_inventory
    order[:items].each do |item|
      stock = get_current_stock(item[:product_id])
      if stock < item[:quantity]
        @errors << "Insufficient stock for #{item[:product_id]}"
        return false
      end
    end
    true
  end

  def get_current_stock(product_id)
    # Simulated database call
    inventory_db = {
      "PROD001" => 50,
      "PROD002" => 30,
      "PROD003" => 100
    }
    inventory_db[product_id] || 0
  end

  # Payment processing responsibilities
  def process_payment
    total = calculate_total

    begin
      # Simulate payment gateway call
      response = charge_credit_card(
        order[:payment_method][:card_number],
        order[:payment_method][:cvv],
        order[:payment_method][:expiry],
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
    rescue => e
      @errors << "Payment processing error: #{e.message}"
      false
    end
  end

  def charge_credit_card(card_number, cvv, expiry, amount)
    # Simulate payment gateway
    if card_number.length == 16 && cvv.length == 3
      { success: true, transaction_id: "TXN#{rand(100000)}" }
    else
      { success: false, error: "Invalid card details" }
    end
  end

  def calculate_total
    subtotal = order[:items].sum { |item| item[:price] * item[:quantity] }
    tax = subtotal * 0.08
    shipping = calculate_shipping_cost
    subtotal + tax + shipping
  end

  # Shipping responsibilities
  def calculate_shipping
    cost = calculate_shipping_cost
    @order[:shipping_cost] = cost
    @order[:estimated_delivery] = calculate_delivery_date
  end

  def calculate_shipping_cost
    zip = order[:shipping_address][:zip]
    total_weight = order[:items].sum { |item| item[:weight] * item[:quantity] }

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
    zip = order[:shipping_address][:zip]
    days = zip.start_with?("9") ? 5 : 3
    (Time.now + (days * 24 * 60 * 60)).strftime("%Y-%m-%d")
  end

  # Inventory management responsibilities
  def update_inventory
    order[:items].each do |item|
      current_stock = get_current_stock(item[:product_id])
      new_stock = current_stock - item[:quantity]
      save_stock(item[:product_id], new_stock)

      if new_stock < 10
        send_low_stock_alert(item[:product_id], new_stock)
      end
    end
  end

  def save_stock(product_id, quantity)
    # Simulated database update
    puts "Updating inventory: #{product_id} -> #{quantity} units"
  end

  def send_low_stock_alert(product_id, quantity)
    # Simulated email to warehouse
    puts "LOW STOCK ALERT: #{product_id} only has #{quantity} units remaining"
  end

  # Email notification responsibilities
  def send_confirmation_email
    email_body = build_confirmation_email
    send_email(
      to: order[:customer_email],
      subject: "Order Confirmation ##{order[:id]}",
      body: email_body
    )
  end

  def send_shipping_notification
    email_body = build_shipping_email
    send_email(
      to: order[:customer_email],
      subject: "Your order has shipped!",
      body: email_body
    )
  end

  def build_confirmation_email
    <<~EMAIL
      Thank you for your order!

      Order ID: #{order[:id]}
      Total: $#{calculate_total}

      Items:
      #{order[:items].map { |i| "- #{i[:name]} x#{i[:quantity]}" }.join("\n")}

      Estimated delivery: #{order[:estimated_delivery]}
    EMAIL
  end

  def build_shipping_email
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

  # Logging and analytics responsibilities
  def log_order
    log_entry = {
      timestamp: Time.now,
      order_id: order[:id],
      customer: order[:customer_email],
      total: calculate_total,
      status: "completed"
    }

    write_to_log(log_entry)
  end

  def write_to_log(entry)
    # Simulated logging system
    puts "LOG: #{entry.inspect}"
  end

  def update_analytics
    total = calculate_total

    # Track revenue
    update_daily_revenue(total)

    # Track popular products
    order[:items].each do |item|
      increment_product_sales(item[:product_id], item[:quantity])
    end

    # Track customer metrics
    increment_customer_order_count(order[:customer_email])
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
