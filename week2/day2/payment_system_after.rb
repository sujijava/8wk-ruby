# Week 2, Day 2: Open/Closed Principle - YOUR SOLUTION
# Refactor the payment system to support multiple providers
# without modifying existing code
#
# Requirements:
# 1. Support PayPal, Stripe, and Square
# 2. Don't modify PayPal code when adding Stripe/Square
# 3. Make adding new providers trivial (10-20 lines)
# 4. Share common behavior (fee calculation, error handling)
# 5. Keep provider-specific logic isolated

require "json"
require "securerandom"
require "pry"

# =============================================================================
# YOUR CODE HERE
#
# Design hints:
# - Consider a base PaymentProvider class or duck typing
# - Think about what behavior is common vs provider-specific
# - How will the main PaymentSystem class use these providers?
# - Should providers be injected or created internally?
#
# Example structure (you can modify this):
#

class PaymentProviderFactory
  def self.build_provider(provider_name)
    case provider_name
    when :paypal
      return PayPalProvider.new
    when :stripe
      return StripeProvider.new
    when :square
      return SquareProvider.new
    end
  end
end

class PaymentSystem
  def initialize
  end

  # PaymentService(PaypalProvider.new).charge
  def process_payment(amount:, provider:, details:)
    provider = PaymentProviderFactory.build_provider(provider)
    provider.charge(amount, details)
  end
end

class PaymentProvider
  def charge(amount, details)
    raise NotImplementedError
  end

  def refund 
    raise NotImplementedError
  end

  def record_failure(amount, provider_name, error_message)
    @failed_transactions << {
      amount: amount,
      provider: provider_name,
      error: error_message,
      timestamp: Time.now
    }
    puts "✗ #{provider_name} payment failed: #{error_message}"
  end
end

class PayPalProvider < PaymentProvider
  def initialize
    @transactions = []
    @failed_transactions = []
  end

  def charge(amount, payment_details)
    return false if !validate_email(payment_details)
    
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

  def refund(transaction_id)
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

  private
  
  def validate_email(payment_details)
    unless payment_details[:email]
      record_failure(amount, "PayPal", "Missing email address")
      return false
    end
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

  def calculate_paypal_fee(amount)
    (amount * 0.029) + 0.30
  end
end
#
class StripeProvider < PaymentProvider
  def charge(amount, payment_details)
    "Stripe charge completed"
  end

  def refund
    "Stripe refund completed"
  end
end

class SquareProvider < PaymentProvider
  def charge(amount, payment_details)
    "Square charge completed"
  end

  def refund
    "Square refund completed"
  end
end

# =============================================================================

# Test your implementation
if __FILE__ == $0

  # TODO: Create payment system with multiple providers
  system = PaymentSystem.new

  puts "Testing multiple payment providers...\n\n"

  # Test PayPal
  system.process_payment(amount: 100.00, provider: :paypal, details: { email: "customer1@example.com" })

  # Test Stripe
  system.process_payment(amount: 250.50, provider: :stripe, details: { card_token: "tok_visa" })

  # Test Square
  system.process_payment(amount: 75.25, provider: :square, details: { nonce: "cnon_test", location_id: "LOC123" })

  # Generate report showing all providers
  # system.generate_report
end
