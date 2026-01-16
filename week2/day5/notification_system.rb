# Notification System Design
# Applies SOLID principles to create an extensible notification system

# Base Notification class
class Notification
  attr_reader :recipient, :message, :priority, :metadata

  def initialize(recipient:, message:, priority: :normal, **metadata)
    @recipient = recipient
    @message = message
    @priority = priority
    @metadata = metadata
  end

  def to_s
    "Notification to #{recipient}: #{message}"
  end
end

# Delivery Channel Interface (Strategy Pattern)
# Each channel implements the deliver method
module DeliveryChannel
  def deliver(notification)
    raise NotImplementedError, "#{self.class} must implement #deliver"
  end

  def name
    self.class.name.gsub(/Channel$/, '').downcase
  end
end

# Concrete Delivery Channels
class EmailChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[EMAIL] To: #{notification.recipient}"
    puts "        Subject: Notification"
    puts "        Body: #{notification.message}"
    { status: :sent, channel: :email, recipient: notification.recipient }
  end
end

class SmsChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[SMS] To: #{notification.recipient}"
    puts "      Message: #{notification.message[0..160]}"
    { status: :sent, channel: :sms, recipient: notification.recipient }
  end
end

class PushChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[PUSH] Device: #{notification.recipient}"
    puts "       Alert: #{notification.message}"
    { status: :sent, channel: :push, recipient: notification.recipient }
  end
end

class SlackChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[SLACK] Channel: #{notification.recipient}"
    puts "        Message: #{notification.message}"
    { status: :sent, channel: :slack, recipient: notification.recipient }
  end
end

# Delivery Strategy Interface
# Determines WHEN to send notifications
class DeliveryStrategy
  def schedule(notification, channel)
    raise NotImplementedError, "#{self.class} must implement #schedule"
  end

  def flush
    # Override in batched strategies
  end
end

# Immediate Delivery Strategy
class ImmediateDelivery < DeliveryStrategy
  def schedule(notification, channel)
    channel.deliver(notification)
  end
end

# Batched Delivery Strategy
class BatchedDelivery < DeliveryStrategy
  attr_reader :batch_size, :queue

  def initialize(batch_size: 5)
    @batch_size = batch_size
    @queue = []
  end

  def schedule(notification, channel)
    @queue << { notification: notification, channel: channel }
    puts "[BATCHED] Queued notification (#{@queue.size}/#{@batch_size})"

    flush if @queue.size >= @batch_size
  end

  def flush
    return [] if @queue.empty?

    puts "\n--- Flushing batch (#{@queue.size} notifications) ---"
    results = @queue.map do |item|
      item[:channel].deliver(item[:notification])
    end
    @queue.clear
    puts "--- Batch complete ---\n\n"
    results
  end
end

# User Preferences
class UserPreferences
  attr_reader :user_id, :channel_preferences, :delivery_strategy

  def initialize(user_id)
    @user_id = user_id
    @channel_preferences = {}
    @delivery_strategy = :immediate
  end

  def enable_channel(channel_name)
    @channel_preferences[channel_name] = true
  end

  def disable_channel(channel_name)
    @channel_preferences[channel_name] = false
  end

  def channel_enabled?(channel_name)
    @channel_preferences.fetch(channel_name, true)
  end

  def set_delivery_strategy(strategy)
    @delivery_strategy = strategy
  end
end

# Notification Service (Facade Pattern)
# Single entry point for sending notifications
class NotificationService
  def initialize
    @channels = {}
    @strategies = {}
    @user_preferences = {}
    @delivery_log = []
  end

  def register_channel(name, channel)
    @channels[name] = channel
    self
  end

  def register_strategy(name, strategy)
    @strategies[name] = strategy
    self
  end

  def set_user_preferences(user_id, preferences)
    @user_preferences[user_id] = preferences
    self
  end

  def send_notification(notification, channels: [:email], strategy: :immediate)
    user_prefs = @user_preferences[notification.recipient]

    channels.each do |channel_name|
      # Check user preferences
      if user_prefs && !user_prefs.channel_enabled?(channel_name)
        puts "[SKIPPED] #{channel_name} disabled for #{notification.recipient}"
        next
      end

      channel = @channels[channel_name]
      unless channel
        puts "[ERROR] Unknown channel: #{channel_name}"
        next
      end

      # Use user's preferred strategy if available
      strategy_name = user_prefs&.delivery_strategy || strategy
      delivery_strategy = @strategies[strategy_name]

      unless delivery_strategy
        puts "[ERROR] Unknown strategy: #{strategy_name}"
        next
      end

      result = delivery_strategy.schedule(notification, channel)
      @delivery_log << result if result
    end
  end

  def flush_batches
    @strategies.each_value do |strategy|
      if strategy.respond_to?(:flush)
        results = strategy.flush
        results.each { |result| @delivery_log << result } if results
      end
    end
  end

  def delivery_log
    @delivery_log
  end
end

# Example Usage
if __FILE__ == $0
  puts "=== Notification System Demo ===\n\n"

  # Setup service
  service = NotificationService.new

  # Register channels
  service.register_channel(:email, EmailChannel.new)
         .register_channel(:sms, SmsChannel.new)
         .register_channel(:push, PushChannel.new)
         .register_channel(:slack, SlackChannel.new)

  # Register strategies
  service.register_strategy(:immediate, ImmediateDelivery.new)
         .register_strategy(:batched, BatchedDelivery.new(batch_size: 3))

  # Configure user preferences
  user1_prefs = UserPreferences.new("user1")
  user1_prefs.enable_channel(:email)
  user1_prefs.enable_channel(:push)
  user1_prefs.disable_channel(:sms)
  service.set_user_preferences("user1", user1_prefs)

  user2_prefs = UserPreferences.new("user2")
  user2_prefs.set_delivery_strategy(:batched)
  service.set_user_preferences("user2", user2_prefs)

  # Send immediate notifications
  puts "--- Immediate Notifications ---\n"
  notification1 = Notification.new(
    recipient: "user1",
    message: "Your order has shipped!",
    priority: :high
  )
  service.send_notification(notification1, channels: [:email, :sms, :push])

  puts "\n--- Multi-channel Notification ---\n"
  notification2 = Notification.new(
    recipient: "team@company.com",
    message: "Deployment completed successfully",
    priority: :normal
  )
  service.send_notification(notification2, channels: [:email, :slack])

  # Send batched notifications
  puts "\n--- Batched Notifications ---\n"
  3.times do |i|
    notification = Notification.new(
      recipient: "user2",
      message: "Daily update ##{i + 1}",
      priority: :low
    )
    service.send_notification(notification, channels: [:email])
  end

  # Manual flush (or could be scheduled)
  puts "\n--- Flushing Remaining Batches ---\n"
  service.flush_batches

  puts "\n=== Demo Complete ==="
end
