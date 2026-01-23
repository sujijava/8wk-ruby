# Week 2, Day 2: Open/Closed Principle (OCP)

## Objective
Extend a payment system to support multiple payment providers (Stripe, Square) without modifying the existing PayPal implementation code.

## The Principle

**"Software entities should be open for extension, but closed for modification."**

This means:
- **Open for extension:** You can add new functionality or behavior
- **Closed for modification:** You shouldn't need to change existing, working code

## The Problem

The `PaymentSystem` class in `payment_system_before.rb` currently only supports PayPal. The code is working and tested in production. Now the business wants to add:
1. **Stripe** payment processing
2. **Square** payment processing

The naive approach would be to add `if/elsif/else` statements for each provider, but this:
- Modifies existing code (violates OCP)
- Makes the class grow with each new provider
- Increases the risk of breaking PayPal when adding Stripe
- Makes testing harder (more branches to cover)

## Your Task

Create `payment_system_after.rb` that:

1. **Uses polymorphism** to support multiple payment providers
2. **Doesn't modify the PayPal implementation** when adding Stripe/Square
3. **Makes adding new providers trivial** (should be ~10-20 lines each)
4. **Maintains a consistent interface** for all payment methods

## Design Approaches

Consider these patterns:

### Approach 1: Strategy Pattern with Base Class
```ruby
class PaymentProvider
  def charge(amount, payment_details)
    raise NotImplementedError
  end
end

class PayPalProvider < PaymentProvider
  def charge(amount, payment_details)
    # PayPal-specific logic
  end
end

class StripeProvider < PaymentProvider
  def charge(amount, payment_details)
    # Stripe-specific logic
  end
end
```

### Approach 2: Duck Typing (Ruby way)
```ruby
# Just implement the interface - no inheritance required
class PayPalProvider
  def charge(amount, payment_details)
    # ...
  end
end

class StripeProvider
  def charge(amount, payment_details)
    # ...
  end
end
```

### Approach 3: Factory Pattern
```ruby
class PaymentProviderFactory
  def self.create(provider_name)
    case provider_name
    when :paypal then PayPalProvider.new
    when :stripe then StripeProvider.new
    # ...
    end
  end
end
```

## Requirements

Your payment system must support:

### PayPal
- Charges via REST API
- Requires: email, amount
- Returns transaction ID
- Has 2.9% + $0.30 fee structure

### Stripe
- Charges via token-based API
- Requires: card token, amount
- Returns charge ID
- Has 2.9% + $0.30 fee structure
- Supports payment intents for complex flows

### Square
- Charges via location-based API
- Requires: nonce, amount, location_id
- Returns payment ID
- Has 2.6% + $0.10 fee structure
- Includes built-in fraud detection

## Questions to Consider

1. Should payment providers share common behavior (fees, error handling)?
2. How will you handle provider-specific features (e.g., Stripe's payment intents)?
3. Should the main `PaymentSystem` class know about all providers, or use a factory?
4. How would you add a 4th provider (Apple Pay) without touching existing code?
5. How will you test each provider in isolation?

## Testing Your Work

Run the original code:
```bash
ruby payment_system_before.rb
```

Then implement your refactored version:
```bash
ruby payment_system_after.rb
```

Both should produce similar output, but the `after` version should make adding new providers trivial.

## Time Allocation (45-60 min)

- **10 min:** Analyze the before code and identify what needs to change
- **15 min:** Design your provider abstraction (base class? duck typing?)
- **20 min:** Implement PayPal, Stripe, and Square providers
- **10 min:** Wire everything together and test
- **5 min:** Add one more provider to prove extensibility

## Success Criteria

- Adding a new payment provider requires NO changes to existing provider code
- Each provider is isolated and testable independently
- The main payment system doesn't need giant if/elsif blocks
- Common behavior (like fee calculation) is shared/reused
- Provider-specific logic stays in provider classes

## Bonus Challenges

1. **Add a provider registry** so providers can self-register
2. **Implement a composite provider** that tries multiple providers in sequence
3. **Add validation** - ensure each provider implements required methods
4. **Create a mock provider** for testing without hitting real APIs
5. **Add provider capabilities** - some support refunds, some don't
6. **Implement retry logic** that works for all providers
