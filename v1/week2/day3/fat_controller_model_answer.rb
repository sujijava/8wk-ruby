# Week 2, Day 3: Service Objects - MODEL ANSWER
# Refactoring a fat controller using service objects and the orchestrator pattern

require "json"
require "securerandom"

# =============================================================================
# Result Object Pattern
# =============================================================================

class Result
  attr_reader :success, :data, :error, :status_code

  def initialize(success:, data: nil, error: nil, status_code: nil)
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

  def self.failure(error:, status_code: 422)
    new(success: false, error: error, status_code: status_code)
  end
end

# =============================================================================
# Simulated Rails components (same as before)
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
                :discount_amount, :status, :created_at, :transaction_id

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
    @transaction_id = nil
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
      status: @status,
      transaction_id: @transaction_id
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

class OrderMailer
  def self.confirmation_email(order, user)
    puts "  [EMAIL] Sending confirmation email to #{user.email} for order #{order.id}"
  end

  def self.shipping_notification(order, user)
    puts "  [EMAIL] Sending shipping notification to #{user.email}"
  end
end

class PaymentGateway
  def self.charge(card_token, amount)
    puts "  [PAYMENT] Charging $#{amount} to card #{card_token}"
    if rand < 0.95
      { success: true, transaction_id: "txn_#{SecureRandom.hex(8)}" }
    else
      { success: false, error: "Payment declined" }
    end
  end
end

class Analytics
  def self.track(event, data)
    puts "  [ANALYTICS] Tracking: #{event} - #{data.inspect}"
  end
end

# =============================================================================
# Service Objects - Individual Responsibilities
# =============================================================================

# Validates order parameters
class ValidateOrderService
  def initialize(params:)
    @params = params
  end

  def call
    return Result.failure(error: "Order must have at least one item", status_code: 422) unless @params[:items]&.any?
    return Result.failure(error: "Shipping address is required", status_code: 422) unless @params[:shipping_address]
    return Result.failure(error: "Payment method is required", status_code: 422) unless @params[:card_token]

    Result.success
  end
end

# Builds order with items and validates product availability
class BuildOrderService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    order = Order.new(user_id: @user.id)
    order.items = []

    @params[:items].each do |item_params|
      product = Product.find(item_params[:product_id])

      return Result.failure(error: "Product #{item_params[:product_id]} not found", status_code: 404) unless product

      quantity = item_params[:quantity].to_i
      if product.stock < quantity
        return Result.failure(error: "Insufficient stock for #{product.name}", status_code: 422)
      end

      order.items << {
        product_id: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity
      }
    end

    Result.success(order)
  end
end

# Calculates pricing with discounts, tax, and shipping
class CalculatePriceService
  TAX_RATE = 0.08
  SHIPPING_COST = 9.99
  FREE_SHIPPING_THRESHOLD = 100

  def initialize(order:, params:)
    @order = order
    @params = params
  end

  def call
    @order.subtotal = @order.items.sum { |item| item[:price] * item[:quantity] }

    apply_coupon if @params[:coupon_code]

    taxable_amount = @order.subtotal - @order.discount_amount
    @order.tax = taxable_amount * TAX_RATE
    @order.shipping = taxable_amount >= FREE_SHIPPING_THRESHOLD ? 0 : SHIPPING_COST
    @order.total = taxable_amount + @order.tax + @order.shipping

    Result.success(@order)
  end

  private

  def apply_coupon
    coupon = Coupon.find_by_code(@params[:coupon_code])
    return unless coupon
    return if @order.subtotal < coupon.min_purchase

    @order.discount_amount = if coupon.discount_type == :percentage
      @order.subtotal * (coupon.discount_value / 100.0)
    elsif coupon.discount_type == :fixed
      coupon.discount_value
    else
      0
    end

    puts "  [DISCOUNT] Applied #{coupon.code}: -$#{@order.discount_amount.round(2)}"
  end
end

# Processes payment through gateway
class ProcessPaymentService
  def initialize(order:, card_token:, gateway: PaymentGateway)
    @order = order
    @card_token = card_token
    @gateway = gateway
  end

  def call
    response = @gateway.charge(@card_token, @order.total)

    if response[:success]
      @order.transaction_id = response[:transaction_id]
      Result.success(@order)
    else
      Result.failure(error: response[:error] || "Payment failed", status_code: 402)
    end
  end
end

# Updates inventory after successful order
class UpdateInventoryService
  def initialize(order:)
    @order = order
  end

  def call
    @order.items.each do |item|
      product = Product.find(item[:product_id])
      product.decrement!(:stock, item[:quantity])
    end

    Result.success
  end
end

# Updates user account with order count and loyalty points
class UpdateAccountService
  def initialize(user:, order:)
    @user = user
    @order = order
  end

  def call
    @user.increment!(:order_count)

    points_earned = @order.total.to_i
    @user.increment!(:loyalty_points, points_earned)

    Result.success
  end
end

# Sends customer notifications
class NotifyCustomerService
  def initialize(order:, user:, mailer: OrderMailer)
    @order = order
    @user = user
    @mailer = mailer
  end

  def call
    @mailer.confirmation_email(@order, @user)
    @mailer.shipping_notification(@order, @user)

    Result.success
  end
end

# Tracks analytics events
class TrackAnalyticsService
  def initialize(order:, user:, tracker: Analytics)
    @order = order
    @user = user
    @tracker = tracker
  end

  def call
    @tracker.track("order_created", {
      order_id: @order.id,
      user_id: @user.id,
      total: @order.total,
      item_count: @order.items.length
    })

    @tracker.track("revenue", {
      amount: @order.total,
      source: "web"
    })

    Result.success
  end
end

# =============================================================================
# Orchestrator Service - Coordinates all other services
# =============================================================================

class CreateOrderService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    # 1. Validate
    result = ValidateOrderService.new(params: @params).call
    return result if result.failure?

    # 2. Build order
    result = BuildOrderService.new(user: @user, params: @params).call
    return result if result.failure?
    order = result.data

    # 3. Calculate pricing
    result = CalculatePriceService.new(order: order, params: @params).call
    return result if result.failure?
    order = result.data

    # 4. Process payment
    result = ProcessPaymentService.new(order: order, card_token: @params[:card_token]).call
    return result if result.failure?
    order = result.data

    # 5. Confirm and save order
    order.status = "confirmed"
    order.save!

    # 6. Update inventory
    UpdateInventoryService.new(order: order).call

    # 7. Update user account
    UpdateAccountService.new(user: @user, order: order).call

    # 8. Send notifications
    NotifyCustomerService.new(order: order, user: @user).call

    # 9. Track analytics
    TrackAnalyticsService.new(order: order, user: @user).call

    # Return success with order
    Result.success(order, status_code: 201)
  end
end

# =============================================================================
# Refactored Thin Controller
# =============================================================================

class OrdersController < ApplicationController
  def create
    result = CreateOrderService.new(user: current_user, params: params).call

    if result.success?
      render json: result.data.as_json, status: result.status_code
    else
      render json: { error: result.error }, status: result.status_code
    end
  end
end

# =============================================================================
# Test the refactored code
# =============================================================================

if __FILE__ == $0
  puts "=" * 80
  puts "REFACTORED: Thin Controller with Service Objects"
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
  puts "BENEFITS OF THIS REFACTORING:"
  puts "=" * 80
  puts "1. SINGLE RESPONSIBILITY PRINCIPLE"
  puts "   - Each service has ONE clear purpose"
  puts "   - ValidateOrderService only validates"
  puts "   - ProcessPaymentService only handles payment"
  puts ""
  puts "2. TESTABLE IN ISOLATION"
  puts "   - No HTTP context needed"
  puts "   - Easy to mock dependencies (gateway, mailer, analytics)"
  puts "   - Can test each service independently"
  puts ""
  puts "3. REUSABLE BUSINESS LOGIC"
  puts "   - Call from background jobs, console, rake tasks"
  puts "   - Not trapped in controller layer"
  puts ""
  puts "4. THIN CONTROLLER (8 lines)"
  puts "   - Only handles HTTP concerns"
  puts "   - Delegates to orchestrator service"
  puts ""
  puts "5. CLEAR FLOW WITH ORCHESTRATOR"
  puts "   - CreateOrderService coordinates everything"
  puts "   - Easy to see the order of operations"
  puts "   - Can add/remove steps easily"
  puts ""
  puts "6. DEPENDENCY INJECTION"
  puts "   - Services accept gateway, mailer, tracker"
  puts "   - Easy to swap implementations for testing"
  puts ""
  puts "7. CONSISTENT ERROR HANDLING"
  puts "   - All services use Result pattern"
  puts "   - Early returns on failure"
  puts "   - Proper status codes"
  puts "=" * 80
  puts ""
  puts "KEY PATTERNS USED:"
  puts "- Service Objects (single responsibility classes)"
  puts "- Orchestrator Pattern (CreateOrderService coordinates)"
  puts "- Result Object Pattern (consistent success/failure)"
  puts "- Dependency Injection (testable collaborators)"
  puts "=" * 80
end
