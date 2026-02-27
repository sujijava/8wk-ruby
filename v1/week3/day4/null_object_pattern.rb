# Week 3, Day 4: Null Object Pattern
# Topic: Refactoring nil checks using the Null Object Pattern
#
# PROBLEM:
# The code below is riddled with nil checks for user subscriptions.
# Every time we access a subscription, we have to check if it exists.
# This makes the code verbose, error-prone, and hard to maintain.
#
# TASK:
# Refactor this code using the Null Object pattern to eliminate
# the nil checks while maintaining the same behavior.
#
# LEARNING OBJECTIVES:
# - Understand when and why to use the Null Object pattern
# - Practice replacing conditional logic with polymorphism
# - Learn to handle "absence of value" elegantly without nil checks

# Current implementation with nil checks everywhere
class User
  attr_reader :name, :email
  attr_accessor :subscription

  def initialize(name, email, subscription = nil)
    @name = name
    @email = email
    @subscription = subscription
  end
end

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
end

# Service classes riddled with nil checks
class UserDashboard
  def initialize(user)
    @user = user
  end

  def welcome_message
    if @user.subscription.nil?
      "Welcome #{@user.name}! Upgrade to unlock premium features."
    elsif @user.subscription.active?
      if @user.subscription.premium?
        "Welcome back, Premium Member #{@user.name}!"
      else
        "Welcome back, #{@user.name}!"
      end
    else
      "Welcome #{@user.name}! Your subscription has expired."
    end
  end

  def available_features
    features = ['basic_search', 'profile']

    if !@user.subscription.nil? && @user.subscription.active?
      features << 'advanced_search'
      features << 'analytics' if @user.subscription.premium?
      features << 'api_access' if @user.subscription.premium?
    end

    features
  end

  def project_limit
    if @user.subscription.nil?
      1
    elsif @user.subscription.active?
      @user.subscription.max_projects
    else
      1
    end
  end
end

class PricingCalculator
  def calculate_price(user, base_price)
    if user.subscription.nil?
      base_price
    elsif user.subscription.active?
      discount = user.subscription.discount_percentage
      base_price * (1 - discount / 100.0)
    else
      base_price
    end
  end
end

class ReportGenerator
  def generate_user_report(user)
    report = {
      name: user.name,
      email: user.email
    }

    if user.subscription.nil?
      report[:subscription_status] = 'none'
      report[:plan] = 'free'
      report[:expires_at] = nil
    else
      if user.subscription.active?
        report[:subscription_status] = 'active'
      else
        report[:subscription_status] = 'expired'
      end
      report[:plan] = user.subscription.plan
      report[:expires_at] = user.subscription.expires_at
    end

    report
  end
end

# Example usage showing all the nil checking in action
if __FILE__ == $0
  puts "=== Before Refactoring (with nil checks) ==="
  puts

  # User without subscription
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

# INSTRUCTIONS FOR REFACTORING:
#
# 1. Create a NullSubscription class that implements the same interface
#    as Subscription but returns sensible defaults for a user without a subscription
#
# 2. Modify the User class to use NullSubscription instead of nil
#
# 3. Refactor UserDashboard, PricingCalculator, and ReportGenerator
#    to remove all nil checks
#
# 4. The output should remain exactly the same, but the code should
#    be cleaner and free of nil checks
#
# BONUS CHALLENGE:
# - Consider adding a GuestSubscription or FreeSubscription concept
#   that's different from NullSubscription
# - Think about edge cases: what if someone tries to upgrade a NullSubscription?
# - How would you handle subscription state transitions?
