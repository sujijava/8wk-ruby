# Week 3, Day 4: Pattern Combinations
# Topic: Solving complex problems by combining multiple design patterns
#
# PROBLEM:
# You're building a notification system for an e-commerce platform.
# The system needs to:
# 1. Send notifications through different channels (email, SMS, push, Slack)
# 2. Apply different formatting/enrichment to messages (add branding, urgent flags, tracking)
# 3. Handle users who haven't configured certain notification channels
# 4. Allow dynamic creation of notifiers based on configuration
# 5. Track and log when notifications are sent
#
# TASK:
# Build a notification system that combines:
# - Strategy Pattern (for different notification channels)
'''
Strategy - send_notification(user, message)
EmailStrategy
SMSStrategy 
PushStrategy
SlackStrategy
NullStrategy

UrgentMessageDecorator
TrackedMessageDecorator 

NotificationSystem
- send_urgent_notification - decorator
- 

StrategyFactory

NotificationLogger(user, channel_name, message, state)
Tracker
'''
# - Decorator Pattern (for message enrichment)
# - Factory Pattern (for creating notifiers)
# - Null Object Pattern (for unconfigured channels)
# - Observer Pattern (for logging/tracking)
#
# LEARNING OBJECTIVES:
# - Practice identifying which patterns fit which requirements
# - Learn to combine patterns without over-engineering
# - Understand how patterns work together in real systems

# Basic implementation without patterns
class NotificationSystem
  def send_notification(user, message, channel_type)
    # This is a naive implementation that will become messy quickly
    # Your job is to refactor it using appropriate patterns

    if channel_type == 'email'
      if user.email.nil? || user.email.empty?
        puts "Cannot send email - user has no email configured"
        return false
      end

      # Add email formatting
      formatted_message = "
<html>
<body>
<img src='logo.png'/>
#{message}
<p>Unsubscribe link</p>
</body>
</html>"

      puts "Sending email to #{user.email}: #{formatted_message}"
      log_notification(user, 'email', message, 'sent')
      true

    elsif channel_type == 'sms'
      if user.phone.nil? || user.phone.empty?
        puts "Cannot send SMS - user has no phone configured"
        return false
      end

      # SMS has character limits
      formatted_message = message[0...160]

      puts "Sending SMS to #{user.phone}: #{formatted_message}"
      log_notification(user, 'sms', message, 'sent')
      true
    end
  end

  def send_urgent_notification(user, message, channel_type)
    # Duplicate logic with urgent styling
    urgent_message = "URGENT: #{message}"
    send_notification(user, urgent_message, channel_type)
  end

  def send_tracked_notification(user, message, channel_type, tracking_id)
    # Duplicate logic with tracking
    tracked_message = "#{message}\n\nTracking: #{tracking_id}"
    send_notification(user, tracked_message, channel_type)
  end

  private

  def log_notification(user, channel, message, status)
    puts "[LOG] #{Time.now} - User: #{user.name}, Channel: #{channel}, Status: #{status}"
  end
end

# User class
class User
  attr_reader :name, :email, :phone, :device_tokens, :slack_webhook

  def initialize(name, email: nil, phone: nil, device_tokens: [], slack_webhook: nil)
    @name = name
    @email = email
    @phone = phone
    @device_tokens = device_tokens
    @slack_webhook = slack_webhook
  end
end

# Example usage showing the problems with current implementation
if __FILE__ == $0
  puts "=== Current Implementation (Without Patterns) ==="
  puts

  system = NotificationSystem.new

  # User with all channels configured
  fully_configured = User.new(
    "Alice",
    email: "alice@example.com",
    phone: "+1234567890",
    device_tokens: ["device123", "device456"],
    slack_webhook: "https://hooks.slack.com/abc123"
  )

  # User with only email
  email_only = User.new("Bob", email: "bob@example.com")

  # User with no channels configured
  no_channels = User.new("Charlie")

  puts "Sending to fully configured user:"
  system.send_notification(fully_configured, "Your order has shipped!", 'email')
  puts

  puts "Sending urgent notification:"
  system.send_urgent_notification(fully_configured, "Payment failed!", 'sms')
  puts

  puts "Sending to user with only email:"
  system.send_notification(email_only, "New message", 'email')
  system.send_notification(email_only, "New message", 'sms')
  puts

  puts "Sending to user with no channels:"
  system.send_notification(no_channels, "You won a prize!", 'email')
  puts
end

# INSTRUCTIONS FOR REFACTORING:
#
# 1. STRATEGY PATTERN:
#    - Create a Notifier interface/base class
#    - Implement concrete notifiers: EmailNotifier, SMSNotifier, PushNotifier, SlackNotifier
#    - Each notifier knows how to send messages through its channel
#
# 2. NULL OBJECT PATTERN:
#    - Create a NullNotifier for when a channel isn't configured
#    - It should respond to the same interface but do nothing (or log gracefully)
#
# 3. DECORATOR PATTERN:
#    - Create notifier decorators: UrgentNotifierDecorator, TrackingNotifierDecorator, BrandingDecorator
#    - These wrap notifiers and enhance the message before sending
#
# 4. FACTORY PATTERN:
#    - Create a NotifierFactory that builds the appropriate notifier based on:
#      * User's configuration (which channels are available)
#      * Channel type requested
#      * Returns NullNotifier if channel not configured
#
# 5. OBSERVER PATTERN:
#    - Create observers that listen for notification events
#    - Implement: LoggingObserver, AnalyticsObserver
#    - Notify observers when notifications are sent
#
# EXPECTED OUTCOME:
# - Clean separation of concerns
# - Easy to add new notification channels
# - Easy to add new message decorations
# - No nil checks scattered throughout code
# - Observable notification events
# - The same user-facing behavior but much better design
#
# BONUS CHALLENGES:
# - Add a CompositeNotifier that can send to multiple channels at once
# - Implement retry logic using the Decorator pattern
# - Add a RateLimitingDecorator that prevents notification spam
# - Create a notification preferences system where users can choose channels per notification type
