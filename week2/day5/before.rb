# Week 2 Day 5: Notification System Design Challenge
# Weekly Review Problem - Design & SOLID Principles

=begin
==================== PROBLEM ====================

Design a notification system where:
- Users can receive notifications via multiple channels: email, SMS, push, Slack
- Some notifications are immediate, some are batched
- The system must be extensible (easy to add new channels or delivery strategies)

==================== REQUIREMENTS ====================

1. MULTIPLE DELIVERY CHANNELS
   - Email
   - SMS
   - Push notifications
   - Slack messages
   - Easy to add new channels without modifying existing code

2. DELIVERY STRATEGIES
   - Immediate: send right away
   - Batched: collect and send in groups (e.g., daily digest)
   - Easy to add new strategies (scheduled, priority-based, etc.)

3. USER PREFERENCES
   - Users can opt in/out of specific channels
   - Users can configure batching preferences
   - Users can choose their preferred delivery strategy

4. EXTENSIBILITY
   - Adding new channels shouldn't require modifying existing code
   - Adding new delivery strategies should be straightforward
   - Follow all SOLID principles

==================== SOLID PRINCIPLES TO APPLY ====================

✓ Single Responsibility Principle (SRP)
  - Each class should have ONE reason to change
  - Example: EmailChannel only handles email delivery
  - Example: BatchedDelivery only handles batching logic

✓ Open/Closed Principle (OCP)
  - Open for extension, closed for modification
  - Should be able to add new channels WITHOUT changing existing code
  - Should be able to add new strategies WITHOUT changing existing code

✓ Liskov Substitution Principle (LSP)
  - Delivery channels should be interchangeable
  - Any channel should work the same way in the system
  - Service shouldn't care which specific channel it's using

✓ Interface Segregation Principle (ISP)
  - Clients don't depend on interfaces they don't use
  - Keep interfaces minimal and focused
  - Don't force classes to implement methods they don't need

✓ Dependency Inversion Principle (DIP)
  - Depend on abstractions, not concretions
  - High-level code should work with interfaces, not specific classes
  - Easy to test with mocks/stubs

==================== DESIGN PATTERNS TO CONSIDER ====================

1. STRATEGY PATTERN
   - For delivery channels (how to deliver)
   - For delivery strategies (when to deliver)

2. FACADE PATTERN
   - Provide simple interface to complex subsystem
   - NotificationService as entry point

3. REGISTRY PATTERN
   - Register channels and strategies dynamically
   - No hardcoded dependencies

==================== YOUR TASK ====================

Implement the following components:

1. Notification class
   - Represents a notification with recipient, message, priority, metadata

2. DeliveryChannel module/interface
   - Define the contract for all delivery channels
   - Implement: EmailChannel, SmsChannel, PushChannel, SlackChannel

3. DeliveryStrategy class/interface
   - Define the contract for delivery strategies
   - Implement: ImmediateDelivery, BatchedDelivery

4. UserPreferences class
   - Manage user's channel preferences
   - Manage user's delivery strategy preference

5. NotificationService class
   - Orchestrate the entire system
   - Register channels and strategies
   - Send notifications respecting user preferences
   - Handle batching and flushing

==================== EXAMPLE USAGE ====================

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
user_prefs = UserPreferences.new("user@example.com")
user_prefs.enable_channel(:email)
user_prefs.enable_channel(:push)
user_prefs.disable_channel(:sms)
user_prefs.set_delivery_strategy(:immediate)
service.set_user_preferences("user@example.com", user_prefs)

# Send notification
notification = Notification.new(
  recipient: "user@example.com",
  message: "Your order has shipped!",
  priority: :high
)

service.send_notification(notification, channels: [:email, :sms, :push])
# Should send via email and push only (sms disabled)

# Batched notifications
user2_prefs = UserPreferences.new("user2@example.com")
user2_prefs.set_delivery_strategy(:batched)
service.set_user_preferences("user2@example.com", user2_prefs)

3.times do |i|
  notification = Notification.new(
    recipient: "user2@example.com",
    message: "Daily update ##{i + 1}"
  )
  service.send_notification(notification, channels: [:email])
end
# Should batch all 3 and send together

service.flush_batches  # Manually flush remaining batches

==================== TESTING REQUIREMENTS ====================

Your implementation should:
1. Have comprehensive unit tests for each component
2. Test user preference enforcement
3. Test batching behavior
4. Test extensibility (add a new channel in tests)
5. Handle edge cases (unknown channel, unknown strategy)

==================== EXTENSIBILITY TEST ====================

Prove the Open/Closed Principle by adding these WITHOUT modifying existing code:

1. New Channel - DiscordChannel
   class DiscordChannel
     include DeliveryChannel
     def deliver(notification)
       # Implementation
     end
   end

2. New Strategy - PriorityDelivery
   - High priority notifications sent immediately
   - Normal priority notifications batched

3. Channel Decorators
   - RetryChannel (wraps any channel with retry logic)
   - RateLimitedChannel (wraps any channel with rate limiting)

==================== DESIGN CONSIDERATIONS ====================

Think about (but don't implement unless you have time):
- How would you handle delivery failures?
- How would you track which notifications were sent?
- How would you persist batched notifications across restarts?
- How would you implement retry logic with exponential backoff?
- How would you add monitoring and alerting?
- How would this work with background jobs (Sidekiq)?

==================== INTERVIEW TALKING POINTS ====================

Be ready to discuss:

1. WHY DID YOU CHOOSE THIS DESIGN?
   - Flexibility for adding channels/strategies
   - Testability of each component
   - Clear separation of concerns
   - Easy to understand and maintain

2. WHAT ARE THE TRADEOFFS?
   - More classes vs. simpler structure
   - In-memory batching vs. persistent queue
   - Synchronous vs. asynchronous delivery
   - Simplicity vs. feature completeness

3. WHAT WOULD YOU CHANGE FOR PRODUCTION?
   - Background job processing (Sidekiq)
   - Persistent queue (Redis/database)
   - Retry logic with exponential backoff
   - Delivery tracking and analytics
   - Rate limiting per channel
   - Template system for notification content

4. HOW WOULD YOU HANDLE HIGH VOLUME?
   - Multiple workers processing in parallel
   - Priority queues
   - Rate limiting per channel
   - Batching by content type

==================== TIME ESTIMATE ====================

This is a 90-120 minute problem:
- 15 min: Design and planning
- 40 min: Core implementation
- 20 min: Tests
- 15 min: Extensions
- 10 min: Documentation

==================== SUCCESS CRITERIA ====================

✓ All SOLID principles demonstrated
✓ At least 4 delivery channels implemented
✓ At least 2 delivery strategies implemented
✓ User preferences enforced correctly
✓ Batching works correctly
✓ Comprehensive tests (15+ test cases)
✓ Can add new channel without modifying existing code
✓ Code is clean and well-organized

==================== GETTING STARTED ====================

1. Read all requirements carefully
2. Sketch out your class structure
3. Start with the simplest component (Notification)
4. Build one channel and strategy to test the design
5. Add remaining channels and strategies
6. Implement user preferences
7. Build the service orchestrator
8. Write tests
9. Prove extensibility with a new channel

==================== HINTS ====================

- Use Ruby modules for behavior contracts (DeliveryChannel)
- Use inheritance for strategy variants (DeliveryStrategy base class)
- Keep deliver() method signature simple: deliver(notification)
- Return results from deliver() for logging: { status: :sent, channel: :email }
- BatchedDelivery should queue internally and flush when batch_size reached
- UserPreferences should default to all channels enabled
- Service should check user preferences before sending
- Use method chaining for fluent API: service.register_channel(...).register_strategy(...)

Good luck! This problem tests your ability to design extensible systems
using SOLID principles - a key skill for senior engineering roles.

=end

# YOUR IMPLEMENTATION STARTS HERE
# Delete this comment and start coding!


require "pry"

class Notification
  attr_reader :recipient, :message, :priority
    def initialize(recipient:, message:, priority: nil, metadata: nil)
      @recipient = recipient
      @message = message
      @priority = priority || "normal" 
   end
end

class DeliveryResult
   attr_accessor :result
   def initialize
      @result = {}
   end

   def builder(status, channel, recipient)
      @result[:status] = status
      @result[:channel] = channel 
      @result[:recipient] = recipient
      return @result
   end
end

# ==================================Channel============

module DeliveryChannel
   def deliver(notification)
      raise NotImplementedError
   end

   def name
      self.class.name.gsub('Channel', '')
   end
end

class EmailChannel
   include DeliveryChannel

   def initialize
      @result = DeliveryResult.new
   end

   def deliver(notification)
      puts "#{name} delivered"
      return @result.builder(:sent, name, notification.recipient)
   end
end

class SmsChannel
   include DeliveryChannel

   def initialize
      @result = DeliveryResult.new
   end

   def deliver(notification)
      puts "#{name} delivered"
      return @result.builder(:sent, name, notification.recipient)
   end
end


class PushChannel
   include DeliveryChannel

   def initialize
      @result = DeliveryResult.new
   end

   def deliver(notification)
      puts "#{name} delivered"
      return @result.builder(:sent, name, notification.recipient)
   end
end

class SlackChannel
   include DeliveryChannel

   def initialize
      @result = DeliveryResult.new
   end

   def deliver(notification)
      puts "#{name} delivered"
      return @result.builder(:sent, name, notification.recipient)
   end
end

# ====================================================

class DeliveryStrategy
   def schedule(notification, channel)
      raise NotImplementedError
   end

   def name 
      self.class.name
   end


   def flush
      puts "#{name} doesn't have flush"
   end
end

class ImmediateDelivery < DeliveryStrategy
   def initialize
   end

   def schedule(notification, channel)
      return channel.deliver(notification)
   end
end

class BatchedDelivery < DeliveryStrategy
   def initialize(batch_size:)
      @batch_size = batch_size
      @queue = []
   end

   def add_to_queue(notification, channel)
      @queue << {notification: notification, channel: channel}
      puts "[BATCHED] Queued notification (#{@queue.length}/#{@batch_size})"
   end

   def schedule(notification, channel)
      add_to_queue(notification, channel)
      flush if @queue.length >= @batch_size
   end

   def flush 
      results = @queue.map do |item|
         item[:channel].deliver(item[:notification])
      end
      @queue.clear
      results
   end
end

class UserPreference
   attr_reader :user_email, :delivery_strategy
   def initialize(user_email)
      @user_email = user_email
      @channel_preference = {}
      @delivery_strategy = :immediate
   end

   def enable_channel(channel_name)
      @channel_preference[channel_name] = true
   end

   def disable_channel(channel_name)
      @channel_preference[channel_name] = false
   end

   def channel_enabled?(channel_name)
      return true if @channel_preference[channel_name].nil?
      return @channel_preference[channel_name]
   end

   def set_delivery_strategy(strategy)
      @delivery_strategy = strategy
  end
end

class NotificationService
   attr_reader :delivery_log
   def initialize
      @channels = {} # channel_name => channel_object
      @strategies = {} # strategy_name => strategy_object
      @user_preferences = {} # user_email => UserPreferences
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

   def set_user_preferences(user_email, preferences)
      @user_preferences[user_email] = preferences
      self
   end

   def send_notification(notification, channels: [:email], strategy: :immediate)
      user_pref = @user_preferences[notification.recipient]
      user_strategy = user_pref.delivery_strategy
      
      @deliver_log  = channels.map do |channel_name|
         next if !user_pref.channel_enabled?(channel_name)
         
         channel = @channels[channel_name]
         if channel.nil?
            raise StandardError, "#{channel_name} not found"
            return
         end
         @strategies[user_strategy].schedule(notification, channel)
      end
      return @deliver_log
   end

   def flush_batches
      @strategies.each do |strategy_name, strategy|
         strategy.flush
      end
   end
end
