# Week 2, Day 2: Open/Closed Principle
# Exercise: Extend this payment system to support Stripe and Square
#           WITHOUT modifying the existing PayPal code
#
# Current Problem:
# - Only supports PayPal
# - Adding new providers means modifying this class
# - Risk of breaking PayPal when adding Stripe
# - Will accumulate if/elsif branches for each provider

require "json"
require "securerandom"

class PaymentSystem
  attr_reader :transactions, :failed_transactions

  def initialize
    @transactions = []
    @failed_transactions = []
  end

  # Process a payment through PayPal
  def process_payment(amount, payment_details)
    unless payment_details[:email]
      record_failure(amount, "PayPal", "Missing email address")
      return false
    end

    # Simulate PayPal API call
    response = charge_paypal(amount, payment_details[:email])

    if response[:success]
      transaction = {
        id: response[:transaction_id],
        amount: amount,
        provider: "PayPal",
        fee: calculate_paypal_fee(amount),
        timestamp: Time.now,
        details: payment_details
      }
      @transactions << transaction
      puts "✓ PayPal payment successful: #{transaction[:id]}"
      true
    else
      record_failure(amount, "PayPal", response[:error])
      false
    end
  end

  # Calculate total revenue
  def total_revenue
    @transactions.sum { |t| t[:amount] }
  end

  # Calculate total fees paid
  def total_fees
    @transactions.sum { |t| t[:fee] }
  end

  # Get net revenue (revenue minus fees)
  def net_revenue
    total_revenue - total_fees
  end

  # Refund a transaction
  def refund(transaction_id)
    transaction = @transactions.find { |t| t[:id] == transaction_id }
    return false unless transaction

    # Simulate PayPal refund API call
    response = refund_paypal(transaction_id)

    if response[:success]
      transaction[:refunded] = true
      transaction[:refunded_at] = Time.now
      puts "✓ Refund successful: #{transaction_id}"
      true
    else
      puts "✗ Refund failed: #{response[:error]}"
      false
    end
  end

  # Generate a report
  def generate_report
    puts "\n" + "=" * 60
    puts "PAYMENT SYSTEM REPORT"
    puts "=" * 60
    puts "Total Transactions: #{@transactions.count}"
    puts "Successful Payments: #{@transactions.count}"
    puts "Failed Payments: #{@failed_transactions.count}"
    puts ""
    puts "Total Revenue: $#{total_revenue.round(2)}"
    puts "Total Fees: $#{total_fees.round(2)}"
    puts "Net Revenue: $#{net_revenue.round(2)}"
    puts ""
    puts "Providers:"
    puts "  - PayPal: #{@transactions.count} transactions"
    puts "=" * 60
  end

  private

  # PayPal-specific fee calculation
  def calculate_paypal_fee(amount)
    (amount * 0.029) + 0.30
  end

  # Simulate PayPal API charge
  def charge_paypal(amount, email)
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

  # Simulate PayPal refund API
  def refund_paypal(transaction_id)
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
# Test the system
# =============================================================================

if __FILE__ == $0
  system = PaymentSystem.new

  puts "Testing PayPal payments...\n\n"

  # Successful payments
  system.process_payment(100.00, { email: "customer1@example.com" })
  system.process_payment(250.50, { email: "customer2@example.com" })
  system.process_payment(75.25, { email: "customer3@example.com" })

  # Failed payment (missing email)
  system.process_payment(50.00, { name: "John Doe" })

  # Process a few more
  system.process_payment(199.99, { email: "customer4@example.com" })
  system.process_payment(49.99, { email: "customer5@example.com" })

  # Test refund
  puts "\n" + "-" * 60
  puts "Testing refunds..."
  puts "-" * 60
  if system.transactions.any?
    system.refund(system.transactions.first[:id])
  end

  # Generate report
  system.generate_report
end

# =============================================================================
# YOUR TASK:
#
# The business now wants to support Stripe and Square payments.
#
# Stripe requirements:
# - Uses card tokens instead of email
# - Same fee structure as PayPal (2.9% + $0.30)
# - Returns a charge ID in format "ch_xxxxx"
# - Supports payment intents for complex flows
#
# Square requirements:
# - Uses a nonce (one-time token) and location_id
# - Different fee structure: 2.6% + $0.10
# - Returns payment ID in format "sq_xxxxx"
# - Has built-in fraud detection
#
# PROBLEM:
# If we add these with if/elsif statements, we'll violate OCP:
# - Modify existing code (risk breaking PayPal)
# - Add complexity with each new provider
# - Make testing harder
# - Couple payment logic to provider details
#
# YOUR SOLUTION:
# Refactor this to use the Open/Closed Principle. Design it so adding
# a new payment provider requires ZERO changes to existing provider code.
# =============================================================================
