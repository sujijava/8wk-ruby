# Week 3, Day 4: Null Object Pattern - Model Solution
#
# Refactored version using the Null Object pattern
# This eliminates all nil checks while maintaining the same behavior

# NullSubscription represents the absence of a subscription
# It implements the same interface as Subscription but with safe defaults
class NullSubscription
  def active?
    false
  end

  def premium?
    false
  end

  def plan
    'free'
  end

  def expires_at
    nil
  end

  def discount_percentage
    0
  end

  def max_projects
    1
  end

  def welcome_message(name)
    "Welcome #{name}! Upgrade to unlock premium features."
  end

  def available_features
    ['basic_search', 'profile']
  end

  def subscription_status
    'none'
  end
end

# Regular subscription with expiration logic
class Subscription
  attr_reader :plan, :expires_at

  def initialize(plan, expires_at)
    @plan = plan
    @expires_at = expires_at
  end

  def active?
    expires_at > Time.now
  end

  def premium?
    plan == 'premium'
  end

  def discount_percentage
    case plan
    when 'premium' then 20
    when 'standard' then 10
    else 0
    end
  end

  def max_projects
    case plan
    when 'premium' then 100
    when 'standard' then 10
    else 1
    end
  end

  def welcome_message(name)
    if active?
      if premium?
        "Welcome back, Premium Member #{name}!"
      else
        "Welcome back, #{name}!"
      end
    else
      "Welcome #{name}! Your subscription has expired."
    end
  end

  def available_features
    features = ['basic_search', 'profile']

    if active?
      features << 'advanced_search'
      if premium?
        features << 'analytics'
        features << 'api_access'
      end
    end

    features
  end

  def subscription_status
    active? ? 'active' : 'expired'
  end
end

# User class now defaults to NullSubscription instead of nil
class User
  attr_reader :name, :email, :subscription

  def initialize(name, email, subscription = nil)
    @name = name
    @email = email
    # Key change: default to NullSubscription instead of nil
    @subscription = subscription || NullSubscription.new
  end
end

# UserDashboard - all nil checks removed!
class UserDashboard
  def initialize(user)
    @user = user
  end

  def welcome_message
    # Polymorphism: subscription handles its own welcome message
    @user.subscription.welcome_message(@user.name)
  end

  def available_features
    # Polymorphism: subscription knows its own features
    @user.subscription.available_features
  end

  def project_limit
    # Polymorphism: subscription knows its own limits
    @user.subscription.max_projects
  end
end

# PricingCalculator - no nil checks needed
class PricingCalculator
  def calculate_price(user, base_price)
    # Works for both active and inactive/null subscriptions
    # Inactive/null subscriptions return 0 discount
    discount = user.subscription.active? ? user.subscription.discount_percentage : 0
    base_price * (1 - discount / 100.0)
  end
end

# ReportGenerator - clean and simple
class ReportGenerator
  def generate_user_report(user)
    # No nil checks needed - subscription always exists
    {
      name: user.name,
      email: user.email,
      subscription_status: user.subscription.subscription_status,
      plan: user.subscription.plan,
      expires_at: user.subscription.expires_at
    }
  end
end

# Example usage - same behavior, cleaner code
if __FILE__ == $0
  puts "=== After Refactoring (Null Object Pattern) ==="
  puts

  # User without subscription (uses NullSubscription automatically)
  free_user = User.new("Alice", "alice@example.com")
  dashboard1 = UserDashboard.new(free_user)

  puts "Free User:"
  puts dashboard1.welcome_message
  puts "Features: #{dashboard1.available_features.join(', ')}"
  puts "Project limit: #{dashboard1.project_limit}"

  calculator = PricingCalculator.new
  puts "Price for $100 item: $#{calculator.calculate_price(free_user, 100)}"
  puts

  # User with active premium subscription
  premium_sub = Subscription.new('premium', Time.now + 365 * 24 * 60 * 60)
  premium_user = User.new("Bob", "bob@example.com", premium_sub)
  dashboard2 = UserDashboard.new(premium_user)

  puts "Premium User:"
  puts dashboard2.welcome_message
  puts "Features: #{dashboard2.available_features.join(', ')}"
  puts "Project limit: #{dashboard2.project_limit}"
  puts "Price for $100 item: $#{calculator.calculate_price(premium_user, 100)}"
  puts

  # User with expired subscription
  expired_sub = Subscription.new('standard', Time.now - 24 * 60 * 60)
  expired_user = User.new("Charlie", "charlie@example.com", expired_sub)
  dashboard3 = UserDashboard.new(expired_user)

  puts "Expired Subscription User:"
  puts dashboard3.welcome_message
  puts "Features: #{dashboard3.available_features.join(', ')}"
  puts "Project limit: #{dashboard3.project_limit}"
  puts "Price for $100 item: $#{calculator.calculate_price(expired_user, 100)}"
  puts

  # Reports
  report_gen = ReportGenerator.new
  puts "=== User Reports ==="
  puts "Free user: #{report_gen.generate_user_report(free_user)}"
  puts "Premium user: #{report_gen.generate_user_report(premium_user)}"
  puts "Expired user: #{report_gen.generate_user_report(expired_user)}"
end

# KEY IMPROVEMENTS:
#
# 1. NullSubscription implements the same interface as Subscription
#    - No nil checks needed anywhere
#    - Provides sensible defaults for users without subscriptions
#
# 2. User class initializes with NullSubscription by default
#    - @subscription is never nil
#    - ||= pattern ensures we always have a valid object
#
# 3. All service classes use polymorphism instead of conditionals
#    - UserDashboard: no if/else chains
#    - PricingCalculator: simple logic, no nil checks
#    - ReportGenerator: straightforward hash building
#
# 4. Each subscription type knows its own behavior
#    - NullSubscription: represents no subscription
#    - Subscription: handles active/expired states internally
#
# 5. Benefits:
#    - Easier to test (no edge cases with nil)
#    - Easier to extend (add new subscription types)
#    - Cleaner code (no defensive programming)
#    - Follows Open/Closed Principle
