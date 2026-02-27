# Week 3, Day 4: Null Object Pattern - Solution
#
# Refactored version using the Null Object pattern
# This file is for your solution

class NullSubscription
  attr_reader :discount_percentage, :max_projects, :available_features, :plan, :subscription_status, :expires_at
  def initialize
    @discount_percentage = 0 
    @max_projects = 1
    @available_features = ['basic_search', 'profile']
    @plan = "free"
    @subscription_status = nil
    @expires_at = nil
  end

  def welcome_message(name)
    "Welcome #{name}! Upgrade to unlock premium features."
  end
end

class StandardSubscription < NullSubscription
  attr_reader :discount_percentage, :max_projects, :available_features, :plan, :subscription_status, :expires_at
  def initialize(expires_at)
    @expires_at = expires_at
    @discount_percentage = 10
    @max_projects = 10
    @available_features = ['basic_search', 'profile', 'advanced_search']
    @plan = "standard"
    @subscription_status = active? "active" : "expired"
  end

  def active?
    @expires_at > Time.now
  end

  def welcome_message(name)
    "Welcome back, #{name}!"
  end
end


class PremiumSubscription < NullSubscription
  attr_reader :discount_percentage, :max_projects, :available_features, :plan, :subscription_status, :expires_at
  def initialize(expires_at)
    @expires_at = expires_at
    @discount_percentage = 20
    @max_projects = 100
    @available_features = ['basic_search', 'profile', 'advanced_search', 'analytics', 'api_access']
    @plan = "premium"
    @subscription_status = active? ? "active" : "expired"
  end

  def active?
    @expires_at > Time.now
  end

  def welcome_message(name)
    "Welcome back, Premium Member #{name}!"
  end
end

# ==============================================
class User
  attr_reader :name, :email
  attr_accessor :subscription

  def initialize(name, email, subscription = nil)
    @name = name
    @email = email
    @subscription = NullSubscription.new
  end

  def subscription
    @subscription = NullSubscription.new if !@subscription.active?

    return @subscription
  end
end

# =================================================================

class UserDashboard
  def initialize(user)
    @user = user
  end

  def welcome_message
    @user.subscription.welcome_message(@user.name)
  end

  def available_features
    @user.subscription.available_features
  end

  def project_limit
    @user.subscription.max_projects
  end
end


class PricingCalculator
  def calculate_price(user, base_price)
    discount_percentage = user.subscription.discount_percentage
    base_price * (1 - discount_percentage / 100.0)    
  end
end


class ReportGenerator
  def generate_user_report(user)
    report = {
      name: user.name,
      email: user.email
    }

    report[:plan] = user.subscription.plan
    report[:expires_at] = user.subscription.expires_at
    report[:subscription_status] = user.subscription.subscription_status
  
    report
  end
end

