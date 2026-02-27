# Week 2, Day 2: Open/Closed Principle - MODEL ANSWER
# A+ Solution demonstrating proper OCP implementation
#
# Key Design Decisions:
# 1. Providers are STATELESS processors - they don't store transactions
# 2. PaymentSystem manages state centrally - easier to aggregate and report
# 3. Result objects instead of booleans - more extensible and informative
# 4. Shared behavior in base class - fee calculation pattern is reusable
# 5. Factory pattern - easy to add new providers without modifying existing code
#
# This design makes adding a 4th provider (Apple Pay, Venmo, etc.) require:
# - Creating a new ~20 line provider class
# - Adding one line to the factory
# - ZERO changes to existing provider code (true OCP)

require "json"
require "securerandom"

# =============================================================================
# RESULT OBJECTS - Better than boolean returns
# =============================================================================

class PaymentResult
  attr_reader :transaction, :error_message

  def initialize(success:, transaction: nil, error_message: nil)
    @success = success
    @transaction = transaction
    @error_message = error_message
  end

  def success?
    @success
  end

  def failed?
    !@success
  end
end

# =============================================================================
# PROVIDER FACTORY - Creates providers without coupling
# =============================================================================

class PaymentProviderFactory
  # Registry pattern - providers can self-register if needed
  @providers = {}

  def self.build_provider(provider_name)
    provider_class = @providers[provider_name]
    raise ArgumentError, "Unknown provider: #{provider_name}" unless provider_class
    provider_class.new
  end

  # For adding providers dynamically (bonus feature)
  def self.register(name, provider_class)
    @providers[name] = provider_class
  end

  def self.providers
    @providers
  end
end

# =============================================================================
# BASE PROVIDER - Defines interface and shared behavior
# =============================================================================

class PaymentProvider
  # Template method - subclasses must implement
  def charge(amount, payment_details)
    raise NotImplementedError, "#{self.class} must implement #charge"
  end

  # Template method - subclasses must implement
  def refund(transaction_id)
    raise NotImplementedError, "#{self.class} must implement #refund"
  end

  # Hook method - subclasses can override for custom validation
  def validate_payment_details(payment_details)
    true
  end

  # Shared behavior - available to all providers
  def provider_name
    self.class.name.gsub('Provider', '')
  end

  protected

  # Shared fee calculation pattern
  # Most providers use: percentage + fixed fee
  def calculate_standard_fee(amount, percentage, fixed_fee)
    (amount * percentage) + fixed_fee
  end

  # Helper for creating success results
  def success_result(transaction_data)
    PaymentResult.new(
      success: true,
      transaction: transaction_data
    )
  end

  # Helper for creating failure results
  def failure_result(error_message)
    PaymentResult.new(
      success: false,
      error_message: error_message
    )
  end
end

# =============================================================================
# PAYPAL PROVIDER - Original implementation, untouched
# =============================================================================

class PayPalProvider < PaymentProvider
  FEE_PERCENTAGE = 0.029
  FEE_FIXED = 0.30

  def charge(amount, payment_details)
    # Validate PayPal-specific requirements
    unless payment_details[:email]
      return failure_result("Missing email address")
    end

    # Simulate PayPal API call
    response = call_paypal_api(amount, payment_details[:email])

    if response[:success]
      transaction = build_transaction(amount, response[:transaction_id], payment_details)
      success_result(transaction)
    else
      failure_result(response[:error])
    end
  end

  def refund(transaction_id)
    # Simulate PayPal refund API
    response = call_paypal_refund_api(transaction_id)

    if response[:success]
      {
        success: true,
        refund_id: response[:refund_id],
        provider: provider_name
      }
    else
      {
        success: false,
        error: response[:error]
      }
    end
  end

  private

  def call_paypal_api(amount, email)
    # Simulate API success/failure (90% success rate)
    if rand < 0.9
      {
        success: true,
        transaction_id: "PP-#{SecureRandom.hex(8).upcase}"
      }
    else
      {
        success: false,
        error: "PayPal payment declined"
      }
    end
  end

  def call_paypal_refund_api(transaction_id)
    # Simulate refund (95% success rate)
    if rand < 0.95
      {
        success: true,
        refund_id: "REF-#{SecureRandom.hex(6).upcase}"
      }
    else
      {
        success: false,
        error: "Refund processing failed"
      }
    end
  end

  def build_transaction(amount, transaction_id, payment_details)
    {
      id: transaction_id,
      amount: amount,
      provider: provider_name,
      fee: calculate_standard_fee(amount, FEE_PERCENTAGE, FEE_FIXED),
      timestamp: Time.now,
      details: payment_details
    }
  end
end

# =============================================================================
# STRIPE PROVIDER - New provider, no changes to PayPal
# =============================================================================

class StripeProvider < PaymentProvider
  FEE_PERCENTAGE = 0.029
  FEE_FIXED = 0.30

  def charge(amount, payment_details)
    # Validate Stripe-specific requirements
    unless payment_details[:card_token]
      return failure_result("Missing card token")
    end

    # Simulate Stripe API call
    response = call_stripe_api(amount, payment_details[:card_token])

    if response[:success]
      transaction = build_transaction(amount, response[:charge_id], payment_details)
      success_result(transaction)
    else
      failure_result(response[:error])
    end
  end

  def refund(transaction_id)
    # Simulate Stripe refund API
    response = call_stripe_refund_api(transaction_id)

    if response[:success]
      {
        success: true,
        refund_id: response[:refund_id],
        provider: provider_name
      }
    else
      {
        success: false,
        error: response[:error]
      }
    end
  end

  # Stripe-specific feature: payment intents for complex flows
  def create_payment_intent(amount, payment_details)
    {
      intent_id: "pi_#{SecureRandom.hex(12)}",
      client_secret: "secret_#{SecureRandom.hex(16)}",
      amount: amount
    }
  end

  private

  def call_stripe_api(amount, card_token)
    # Simulate Stripe API (92% success rate - slightly better than PayPal)
    if rand < 0.92
      {
        success: true,
        charge_id: "ch_#{SecureRandom.hex(12)}"
      }
    else
      {
        success: false,
        error: "Stripe charge failed: insufficient funds"
      }
    end
  end

  def call_stripe_refund_api(transaction_id)
    # Simulate refund (97% success rate)
    if rand < 0.97
      {
        success: true,
        refund_id: "re_#{SecureRandom.hex(10)}"
      }
    else
      {
        success: false,
        error: "Stripe refund failed"
      }
    end
  end

  def build_transaction(amount, charge_id, payment_details)
    {
      id: charge_id,
      amount: amount,
      provider: provider_name,
      fee: calculate_standard_fee(amount, FEE_PERCENTAGE, FEE_FIXED),
      timestamp: Time.now,
      details: payment_details
    }
  end
end

# =============================================================================
# SQUARE PROVIDER - Another new provider, still no changes to existing code
# =============================================================================

class SquareProvider < PaymentProvider
  FEE_PERCENTAGE = 0.026  # Square has better rates: 2.6% + $0.10
  FEE_FIXED = 0.10

  def charge(amount, payment_details)
    # Validate Square-specific requirements
    unless payment_details[:nonce] && payment_details[:location_id]
      return failure_result("Missing nonce or location_id")
    end

    # Simulate Square fraud detection
    if detect_fraud?(payment_details)
      return failure_result("Transaction blocked by fraud detection")
    end

    # Simulate Square API call
    response = call_square_api(amount, payment_details[:nonce], payment_details[:location_id])

    if response[:success]
      transaction = build_transaction(amount, response[:payment_id], payment_details)
      success_result(transaction)
    else
      failure_result(response[:error])
    end
  end

  def refund(transaction_id)
    # Simulate Square refund API
    response = call_square_refund_api(transaction_id)

    if response[:success]
      {
        success: true,
        refund_id: response[:refund_id],
        provider: provider_name
      }
    else
      {
        success: false,
        error: response[:error]
      }
    end
  end

  private

  def detect_fraud?(payment_details)
    # Simulate Square's built-in fraud detection
    # 5% of transactions flagged as potentially fraudulent
    rand < 0.05
  end

  def call_square_api(amount, nonce, location_id)
    # Simulate Square API (88% success rate - includes fraud rejections)
    if rand < 0.88
      {
        success: true,
        payment_id: "sq_#{SecureRandom.hex(10)}"
      }
    else
      {
        success: false,
        error: "Square payment declined"
      }
    end
  end

  def call_square_refund_api(transaction_id)
    # Simulate refund (96% success rate)
    if rand < 0.96
      {
        success: true,
        refund_id: "sqrf_#{SecureRandom.hex(8)}"
      }
    else
      {
        success: false,
        error: "Square refund failed"
      }
    end
  end

  def build_transaction(amount, payment_id, payment_details)
    {
      id: payment_id,
      amount: amount,
      provider: provider_name,
      fee: calculate_standard_fee(amount, FEE_PERCENTAGE, FEE_FIXED),
      timestamp: Time.now,
      details: payment_details
    }
  end
end

# =============================================================================
# PAYMENT SYSTEM - Orchestrates providers and manages state centrally
# =============================================================================

class PaymentSystem
  attr_reader :transactions, :failed_transactions

  def initialize
    @transactions = []
    @failed_transactions = []
    @provider_cache = {}  # Cache provider instances for reuse
  end

  # Main entry point for processing payments
  def process_payment(amount:, provider:, details:)
    provider_instance = get_provider(provider)
    result = provider_instance.charge(amount, details)

    if result.success?
      @transactions << result.transaction
      puts "✓ #{provider_instance.provider_name} payment successful: #{result.transaction[:id]}"
      true
    else
      record_failure(amount, provider_instance.provider_name, result.error_message)
      false
    end
  rescue ArgumentError => e
    puts "✗ Error: #{e.message}"
    false
  end

  # Refund a transaction
  def refund(transaction_id)
    transaction = @transactions.find { |t| t[:id] == transaction_id }
    return false unless transaction

    provider_instance = get_provider(transaction[:provider].downcase.to_sym)
    response = provider_instance.refund(transaction_id)

    if response[:success]
      transaction[:refunded] = true
      transaction[:refunded_at] = Time.now
      transaction[:refund_id] = response[:refund_id]
      puts "✓ Refund successful: #{transaction_id}"
      true
    else
      puts "✗ Refund failed: #{response[:error]}"
      false
    end
  end

  # Calculate total revenue across all providers
  def total_revenue
    @transactions.reject { |t| t[:refunded] }.sum { |t| t[:amount] }
  end

  # Calculate total fees paid to all providers
  def total_fees
    @transactions.reject { |t| t[:refunded] }.sum { |t| t[:fee] }
  end

  # Get net revenue (revenue minus fees)
  def net_revenue
    total_revenue - total_fees
  end

  # Get revenue by provider
  def revenue_by_provider
    @transactions
      .reject { |t| t[:refunded] }
      .group_by { |t| t[:provider] }
      .transform_values { |txns| txns.sum { |t| t[:amount] } }
  end

  # Generate comprehensive report
  def generate_report
    puts "\n" + "=" * 70
    puts "PAYMENT SYSTEM REPORT"
    puts "=" * 70
    puts "Total Transactions: #{@transactions.count}"
    puts "Successful Payments: #{@transactions.count}"
    puts "Failed Payments: #{@failed_transactions.count}"
    puts "Refunded Payments: #{@transactions.count { |t| t[:refunded] }}"
    puts ""
    puts "Financial Summary:"
    puts "  Total Revenue: $#{total_revenue.round(2)}"
    puts "  Total Fees: $#{total_fees.round(2)}"
    puts "  Net Revenue: $#{net_revenue.round(2)}"
    puts ""
    puts "Revenue by Provider:"
    revenue_by_provider.each do |provider, revenue|
      count = @transactions.count { |t| t[:provider] == provider && !t[:refunded] }
      puts "  - #{provider}: #{count} transactions, $#{revenue.round(2)}"
    end
    puts "=" * 70
  end

  private

  # Get or create provider instance (cached for performance)
  def get_provider(provider_name)
    @provider_cache[provider_name] ||= PaymentProviderFactory.build_provider(provider_name)
  end

  def record_failure(amount, provider, error_message)
    @failed_transactions << {
      amount: amount,
      provider: provider,
      error: error_message,
      timestamp: Time.now
    }
    puts "✗ #{provider} payment failed: #{error_message}"
  end
end

# =============================================================================
# DEMONSTRATION: Adding a 4th provider is trivial (no changes to existing code)
# =============================================================================

class VenmoProvider < PaymentProvider
  FEE_PERCENTAGE = 0.019  # Venmo has great rates: 1.9% + $0.10
  FEE_FIXED = 0.10

  def charge(amount, payment_details)
    unless payment_details[:username]
      return failure_result("Missing Venmo username")
    end

    # Simulate Venmo API call
    response = call_venmo_api(amount, payment_details[:username])

    if response[:success]
      transaction = {
        id: response[:payment_id],
        amount: amount,
        provider: provider_name,
        fee: calculate_standard_fee(amount, FEE_PERCENTAGE, FEE_FIXED),
        timestamp: Time.now,
        details: payment_details
      }
      success_result(transaction)
    else
      failure_result(response[:error])
    end
  end

  def refund(transaction_id)
    {
      success: true,
      refund_id: "venmo_ref_#{SecureRandom.hex(6)}",
      provider: provider_name
    }
  end

  private

  def call_venmo_api(amount, username)
    if rand < 0.93
      { success: true, payment_id: "venmo_#{SecureRandom.hex(8)}" }
    else
      { success: false, error: "Venmo payment failed" }
    end
  end
end

# Register all providers with the factory
PaymentProviderFactory.register(:paypal, PayPalProvider)
PaymentProviderFactory.register(:stripe, StripeProvider)
PaymentProviderFactory.register(:square, SquareProvider)
PaymentProviderFactory.register(:venmo, VenmoProvider)

# =============================================================================
# TEST EXECUTION
# =============================================================================

if __FILE__ == $0
  system = PaymentSystem.new

  puts "Testing Open/Closed Principle with multiple payment providers\n\n"
  puts "=" * 70
  puts "PROCESSING PAYMENTS"
  puts "=" * 70
  puts ""

  # Test PayPal (original provider)
  puts "PayPal Payments:"
  system.process_payment(amount: 100.00, provider: :paypal, details: { email: "customer1@example.com" })
  system.process_payment(amount: 250.50, provider: :paypal, details: { email: "customer2@example.com" })
  system.process_payment(amount: 75.25, provider: :paypal, details: { name: "No Email" })  # Should fail
  puts ""

  # Test Stripe (new provider - no PayPal code changed)
  puts "Stripe Payments:"
  system.process_payment(amount: 199.99, provider: :stripe, details: { card_token: "tok_visa" })
  system.process_payment(amount: 449.99, provider: :stripe, details: { card_token: "tok_mastercard" })
  system.process_payment(amount: 50.00, provider: :stripe, details: {})  # Should fail
  puts ""

  # Test Square (another new provider - still no changes to PayPal or Stripe)
  puts "Square Payments:"
  system.process_payment(amount: 325.00, provider: :square, details: { nonce: "cnon_test1", location_id: "LOC123" })
  system.process_payment(amount: 125.75, provider: :square, details: { nonce: "cnon_test2", location_id: "LOC123" })
  puts ""

  # Test Venmo (4th provider added with ~20 lines of code + 1 line registration)
  puts "Venmo Payments:"
  system.process_payment(amount: 89.99, provider: :venmo, details: { username: "@john_doe" })
  system.process_payment(amount: 150.00, provider: :venmo, details: { username: "@jane_smith" })
  puts ""

  # Test unknown provider
  puts "Invalid Provider:"
  system.process_payment(amount: 100.00, provider: :bitcoin, details: {})
  puts ""

  # Test refund
  puts "=" * 70
  puts "TESTING REFUNDS"
  puts "=" * 70
  if system.transactions.any?
    system.refund(system.transactions.first[:id])
  end
  puts ""

  # Generate comprehensive report
  system.generate_report

  # Demonstrate extensibility
  puts "\n" + "=" * 70
  puts "OPEN/CLOSED PRINCIPLE DEMONSTRATION"
  puts "=" * 70
  puts "✓ Original PayPal code: UNCHANGED"
  puts "✓ Added Stripe: NO modifications to PayPal"
  puts "✓ Added Square: NO modifications to PayPal or Stripe"
  puts "✓ Added Venmo: NO modifications to any existing provider"
  puts ""
  puts "Adding a new provider requires:"
  puts "  1. Create new provider class (~20-30 lines)"
  puts "  2. Register with factory (1 line)"
  puts "  3. Changes to existing code: 0"
  puts "=" * 70
end
