# Week 2, Day 3: Service Objects - Part 2
# Exercise: Extract business logic from this fat controller
#
# Current Problems:
# 1. Controller has too many responsibilities (violates SRP)
# 2. Business logic is trapped in the controller (can't reuse)
# 3. Hard to test (need to simulate HTTP requests/responses)
# 4. Mixed concerns: validation, business logic, persistence, emails, analytics
# 5. 80+ lines in a single action

require "json"
require "securerandom"
require "pry"

# =============================================================================
# Result Object Pattern
# =============================================================================

class Result
  attr_accessor :success, :data, :error, :status_code

  def initialize(success: nil, data: nil, error: nil, status_code: nil)
    @success = success
    @data = data
    @error = error
    @status_code = status_code || (success ? 200 : 422)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(data = nil, status_code: 200)
    new(success: true, data: data, status_code: status_code)
  end

  def self.failure(error: nil, errors: [], status_code: 422)
    new(success: false, error: error, errors: errors, status_code: status_code)
  end
end

# =============================================================================
# Simulated Rails components for demonstration
# =============================================================================

class ApplicationController
  attr_accessor :params, :current_user

  def initialize
    @params = {}
    @current_user = nil
  end

  def render(options)
    if options[:json]
      puts "RESPONSE: #{options[:json].to_json}"
      puts "STATUS: #{options[:status]}"
    end
  end
end

class Order
  attr_accessor :id, :user_id, :items, :subtotal, :tax, :shipping, :total,
                :discount_amount, :status, :created_at

  def initialize(attributes = {})
    @id = SecureRandom.uuid
    @user_id = attributes[:user_id]
    @items = attributes[:items] || []
    @subtotal = 0
    @tax = 0
    @shipping = 0
    @total = 0
    @discount_amount = 0
    @status = "pending"
    @created_at = Time.now
  end

  def save!
    puts "  [DB] Order #{@id} saved to database"
    true
  end

  def as_json
    {
      id: @id,
      user_id: @user_id,
      items: @items,
      subtotal: @subtotal,
      tax: @tax,
      shipping: @shipping,
      discount: @discount_amount,
      total: @total,
      status: @status
    }
  end
end

class Product
  attr_accessor :id, :name, :price, :stock

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @price = attributes[:price]
    @stock = attributes[:stock]
  end

  @@products = {
    "prod1" => new(id: "prod1", name: "Widget", price: 29.99, stock: 100),
    "prod2" => new(id: "prod2", name: "Gadget", price: 49.99, stock: 50),
    "prod3" => new(id: "prod3", name: "Gizmo", price: 19.99, stock: 200)
  }

  def self.find(id)
    @@products[id]
  end

  def decrement!(attribute, by = 1)
    case attribute
    when :stock
      @stock -= by
      puts "  [DB] Product #{@id} stock decremented to #{@stock}"
    end
  end
end

class User
  attr_accessor :id, :email, :loyalty_points, :order_count

  def initialize(id:, email:, loyalty_points: 0, order_count: 0)
    @id = id
    @email = email
    @loyalty_points = loyalty_points
    @order_count = order_count
  end

  def increment!(attribute, by = 1)
    case attribute
    when :order_count
      @order_count += by
      puts "  [DB] User #{@id} order count incremented to #{@order_count}"
    when :loyalty_points
      @loyalty_points += by
      puts "  [DB] User #{@id} loyalty points incremented to #{@loyalty_points}"
    end
  end
end

class Coupon
  attr_accessor :code, :discount_type, :discount_value, :min_purchase

  def initialize(attributes = {})
    @code = attributes[:code]
    @discount_type = attributes[:discount_type]
    @discount_value = attributes[:discount_value]
    @min_purchase = attributes[:min_purchase]
  end

  @@coupons = {
    "SAVE10" => new(code: "SAVE10", discount_type: :percentage, discount_value: 10, min_purchase: 50),
    "FLAT20" => new(code: "FLAT20", discount_type: :fixed, discount_value: 20, min_purchase: 100)
  }

  def self.find_by_code(code)
    @@coupons[code]
  end
end

# Simulated mailer
class OrderMailer
  def self.confirmation_email(order, user)
    puts "  [EMAIL] Sending confirmation email to #{user.email} for order #{order.id}"
  end

  def self.shipping_notification(order, user)
    puts "  [EMAIL] Sending shipping notification to #{user.email}"
  end
end

# Simulated payment gateway
class PaymentGateway
  def self.charge(card_token, amount)
    puts "  [PAYMENT] Charging $#{amount} to card #{card_token}"
    # Simulate 95% success rate
    if rand < 0.95
      { success: true, transaction_id: "txn_#{SecureRandom.hex(8)}" }
    else
      { success: false, error: "Payment declined" }
    end
  end
end

# Simulated analytics
class Analytics
  def self.track(event, data)
    puts "  [ANALYTICS] Tracking: #{event} - #{data.inspect}"
  end
end


class OrderValidator
  def initialize(params)
    @params = params
    @result = Result.new
  end

  def validate
    unless @params[:items] && @params[:items].any?
      @result.error = "Order must have at least one item"
      @result.status_code = 422
      return @result
    end

    unless @params[:shipping_address]
      @result.error = "Shipping address is required"
      @result.status_code = 422
      return @result
    end

    unless @params[:card_token]
      @result.error = "Payment method is required"
      @result.status_code = 422
      return @result
    end

    return @result
  end
end


class OrderCreator

  def initialize
    @result = Result.new
  end

  def create(current_user, params)
    order = Order.new(user_id: current_user.id)
    order.items = []

    # Build order items and calculate subtotal
    params[:items].each do |item_params|
      product = Product.find(item_params[:product_id])

      unless product
        @result.error = "Product #{item_params[:product_id]} not found"
        @result.status_code = 404
        return @result
      end

      if product.stock < item_params[:quantity].to_i
        @result.error = "Insufficient stock for #{product.name}"
        @result.status_code = 422
        return @result
      end

      order.items << {
        product_id: product.id,
        name: product.name,
        price: product.price,
        quantity: item_params[:quantity].to_i
      }
    end
    @result.data = order
    @result.success = true
    return @result
  end
end

class PriceCalculator 
  def initialize
    @result = Result.new
  end
  
  def calculate(order, params)
    order.subtotal = order.items.sum { |item| item[:price] * item[:quantity] }

    # Apply coupon if provided
    if params[:coupon_code]
      coupon = Coupon.find_by_code(params[:coupon_code])

      if coupon
        if order.subtotal >= coupon.min_purchase
          if coupon.discount_type == :percentage
            order.discount_amount = order.subtotal * (coupon.discount_value / 100.0)
          elsif coupon.discount_type == :fixed
            order.discount_amount = coupon.discount_value
          end
          puts "  [DISCOUNT] Applied #{coupon.code}: -$#{order.discount_amount.round(2)}"
        else
          puts "  [DISCOUNT] Coupon #{coupon.code} requires minimum purchase of $#{coupon.min_purchase}"
        end
      end
    end

    # Calculate tax (8%)
    taxable_amount = order.subtotal - order.discount_amount
    order.tax = taxable_amount * 0.08

    # Calculate shipping (free over $100, otherwise $9.99)
    order.shipping = taxable_amount >= 100 ? 0 : 9.99

    # Calculate final total
    order.total = taxable_amount + order.tax + order.shipping

    @result.data = order
    return @result
  end
end

class InventoryManager
  def initialize
  end

  def call(order)
      order.items.each do |item|
      product = Product.find(item[:product_id])
      product.decrement!(:stock, item[:quantity])
    end
  end
end

class AccountUpdater
  def initialize
  end

  def call(current_user, order)
    current_user.increment!(:order_count)

    # Award loyalty points (1 point per dollar)
    points_earned = order.total.to_i
    current_user.increment!(:loyalty_points, points_earned)
  end
end
# =============================================================================

class OrdersController < ApplicationController
  def create
    
    validator_result = OrderValidator.new(params).validate
    if validator_result.error
      render json: { error: validator_result.error }, status: validator_result.status_code
      return
    end

    order_creator_result = OrderCreator.new.create(current_user, params)
    if order_creator_result.error
      render json: {error: order_creator_result.error }, status: order_creator_result.status_code
      return 
    end 

    order = order_creator_result.data
    price_calculator_result = PriceCalculator.new.calculate(order, params)
    order = price_calculator_result.data
    
    unless price_calculator_result.success
      render json: { error: price_calculator_result.error }, status: 402
      return
    end

    order.status = "confirmed"
    order.save!

    InventoryManager.new.call(order)
    AccountUpdater.new.call(current_user, order)

    send_emails(order, current_user)
    analytics(order, current_user)

     render json: order.as_json, status: 201
  end

  private 
  def send_emails(order, current_user)
    OrderMailer.confirmation_email(order, current_user)
    OrderMailer.shipping_notification(order, current_user)

  end

  def analytics(order, current_user)
      Analytics.track("order_created", {
      order_id: order.id,
      user_id: current_user.id,
      total: order.total,
      item_count: order.items.length
    })

    Analytics.track("revenue", {
      amount: order.total,
      source: "web"
    })
  end
end

# =============================================================================
# Test the fat controller
# =============================================================================

if __FILE__ == $0
  puts "=" * 80
  puts "DEMONSTRATING THE PROBLEM: Fat Controller with 100+ Lines"
  puts "=" * 80
  puts ""

  controller = OrdersController.new
  controller.current_user = User.new(id: "user123", email: "customer@example.com")
  controller.params = {
    items: [
      { product_id: "prod1", quantity: 2 },
      { product_id: "prod2", quantity: 1 }
    ],
    shipping_address: {
      street: "123 Main St",
      city: "San Francisco",
      state: "CA",
      zip: "94102"
    },
    card_token: "tok_visa_4242",
    coupon_code: "SAVE10"
  }

  puts "Creating order with valid data:"
  puts "-" * 80
  controller.create
  puts ""

  puts "=" * 80
  puts "PROBLEMS WITH THIS CONTROLLER:"
  puts "=" * 80
  puts "1. TOO MANY RESPONSIBILITIES:"
  puts "   - Validation, pricing, payment, inventory, email, analytics"
  puts ""
  puts "2. VIOLATES SINGLE RESPONSIBILITY PRINCIPLE"
  puts "   - Controller should only handle HTTP concerns"
  puts ""
  puts "3. IMPOSSIBLE TO TEST IN ISOLATION"
  puts "   - Need to mock request/response objects"
  puts "   - Need to simulate HTTP context"
  puts ""
  puts "4. BUSINESS LOGIC TRAPPED IN CONTROLLER"
  puts "   - Can't reuse from background jobs"
  puts "   - Can't call from console or other contexts"
  puts ""
  puts "5. HARD TO UNDERSTAND AND MAINTAIN"
  puts "   - 100+ lines doing 10 different things"
  puts "   - Mixed levels of abstraction"
  puts ""
  puts "YOUR TASK:"
  puts "Extract service objects for each responsibility:"
  puts "  - ValidateOrderService"
  puts "  - CalculatePricingService"
  puts "  - ProcessPaymentService"
  puts "  - CreateOrderService (orchestrator)"
  puts "  - UpdateInventoryService"
  puts "  - NotifyCustomerService"
  puts ""
  puts "Controller should become ~10 lines:"
  puts "  result = CreateOrderService.call(params: params, user: current_user)"
  puts "  render json: result.order, status: result.status_code"
  puts "=" * 80
end

# =============================================================================
# YOUR TASK:
#
# Refactor this fat controller by extracting service objects:
#
# 1. Create service objects for each major responsibility:
#    - Order validation
#    - Pricing calculation
#    - Payment processing
#    - Order creation (orchestrator)
#    - Inventory updates
#    - Customer notifications
#    - Analytics tracking
#
# 2. Use dependency injection for:
#    - Payment gateway
#    - Mailer
#    - Analytics
#
# 3. Return result objects instead of booleans
#
# 4. Make the controller thin (5-10 lines)
#
# 5. Ensure services are testable in isolation
#
# Design questions to consider:
# - Should services have a common base class?
# - How do you handle transactions (rollback on failure)?
# - Should services call other services, or should there be an orchestrator?
# - What should result objects contain?
# =============================================================================
