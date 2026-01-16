# Week 2 Day 5: Step-by-Step Implementation Guide

## Overview
You're building a notification system with multiple delivery channels (email, SMS, push, Slack) and delivery strategies (immediate, batched). Focus on SOLID principles and extensibility.

---

## STEP 1: Create the Notification Class (5 minutes)
**Goal:** Simple data object to hold notification information

```ruby
class Notification
  # What you need:
  # - recipient (who gets it)
  # - message (what to send)
  # - priority (optional, default :normal)
  # - metadata (optional, any extra data)

  # Hint: Use attr_reader for read-only access
  # Hint: Use keyword arguments with defaults
end
```

**Test it:**
```ruby
notif = Notification.new(recipient: "test@example.com", message: "Hello")
puts notif.recipient  # => "test@example.com"
puts notif.message    # => "Hello"
puts notif.priority   # => :normal
```

---

## STEP 2: Create DeliveryChannel Interface (5 minutes)
**Goal:** Define the contract that all channels must follow

```ruby
module DeliveryChannel
  # What you need:
  # - deliver(notification) method that all channels must implement
  # - Optional: name method to get channel name

  # Hint: Use raise NotImplementedError for interface methods
end
```

**Why a module?** In Ruby, modules are perfect for defining interfaces/contracts.

---

## STEP 3: Implement ONE Channel (Email) (10 minutes)
**Goal:** Get one channel working before building the rest

```ruby
class EmailChannel
  include DeliveryChannel

  def deliver(notification)
    # What you need:
    # - Print a message showing email was sent
    # - Return a hash: { status: :sent, channel: :email, recipient: ... }

    # Example output:
    # [EMAIL] To: user@example.com
    #         Subject: Notification
    #         Body: Your message here
  end
end
```

**Test it:**
```ruby
channel = EmailChannel.new
notification = Notification.new(recipient: "test@example.com", message: "Hi")
result = channel.deliver(notification)
puts result  # => { status: :sent, channel: :email, recipient: "test@example.com" }
```

---

## STEP 4: Implement Remaining Channels (10 minutes)
**Goal:** Copy the pattern from EmailChannel

```ruby
class SmsChannel
  include DeliveryChannel
  def deliver(notification)
    # Print: [SMS] To: +1234567890
    #              Message: ...
    # Return: { status: :sent, channel: :sms, ... }
  end
end

class PushChannel
  include DeliveryChannel
  def deliver(notification)
    # Print: [PUSH] Device: ...
    #              Alert: ...
    # Return: { status: :sent, channel: :push, ... }
  end
end

class SlackChannel
  include DeliveryChannel
  def deliver(notification)
    # Print: [SLACK] Channel: ...
    #               Message: ...
    # Return: { status: :sent, channel: :slack, ... }
  end
end
```

**Key Point:** All channels have the SAME interface (LSP - Liskov Substitution Principle)

---

## STEP 5: Create DeliveryStrategy Base Class (5 minutes)
**Goal:** Define the contract for delivery strategies

```ruby
class DeliveryStrategy
  def schedule(notification, channel)
    # What you need:
    # - Raise NotImplementedError (this is abstract)
    # - Subclasses will implement this
  end

  def flush
    # Optional method for batched strategies
    # Default: do nothing
  end
end
```

**Why?** Strategies decide WHEN to send (immediately vs batched vs scheduled)

---

## STEP 6: Implement ImmediateDelivery Strategy (5 minutes)
**Goal:** Simplest strategy - send right away

```ruby
class ImmediateDelivery < DeliveryStrategy
  def schedule(notification, channel)
    # What you need:
    # - Call channel.deliver(notification) immediately
    # - Return the result
  end
end
```

**Test it:**
```ruby
strategy = ImmediateDelivery.new
channel = EmailChannel.new
notification = Notification.new(recipient: "test@example.com", message: "Hi")
result = strategy.schedule(notification, channel)
# Should print email delivery immediately
```

---

## STEP 7: Implement BatchedDelivery Strategy (15 minutes)
**Goal:** Queue notifications and send when batch is full

```ruby
class BatchedDelivery < DeliveryStrategy
  def initialize(batch_size: 5)
    # What you need:
    # - @batch_size (how many to queue before sending)
    # - @queue (array to hold queued notifications + channels)
  end

  def schedule(notification, channel)
    # What you need:
    # - Add { notification: notification, channel: channel } to queue
    # - Print: [BATCHED] Queued notification (1/3)
    # - If queue size >= batch_size, call flush
    # - Return nil (not sent yet) or result if flushed
  end

  def flush
    # What you need:
    # - Return [] if queue is empty
    # - Print: "--- Flushing batch (N notifications) ---"
    # - Deliver each queued notification
    # - Collect and return all results
    # - Clear the queue
  end
end
```

**Test it:**
```ruby
strategy = BatchedDelivery.new(batch_size: 3)
channel = EmailChannel.new

# Queue 3 notifications
3.times do |i|
  notif = Notification.new(recipient: "user#{i}@example.com", message: "Test")
  strategy.schedule(notif, channel)  # Should auto-flush on 3rd one
end
```

---

## STEP 8: Implement UserPreferences (10 minutes)
**Goal:** Store user's channel and strategy preferences

```ruby
class UserPreferences
  def initialize(user_id)
    # What you need:
    # - @user_id
    # - @channel_preferences (hash to track enabled/disabled channels)
    # - @delivery_strategy (default: :immediate)
  end

  def enable_channel(channel_name)
    # Set channel_preferences[channel_name] = true
  end

  def disable_channel(channel_name)
    # Set channel_preferences[channel_name] = false
  end

  def channel_enabled?(channel_name)
    # Return channel_preferences[channel_name]
    # Default to true if not set (all channels enabled by default)
  end

  def set_delivery_strategy(strategy)
    # Set @delivery_strategy
  end

  attr_reader :user_id, :delivery_strategy
end
```

**Test it:**
```ruby
prefs = UserPreferences.new("user123")
prefs.disable_channel(:sms)
puts prefs.channel_enabled?(:email)  # => true
puts prefs.channel_enabled?(:sms)    # => false
```

---

## STEP 9: Implement NotificationService (20 minutes)
**Goal:** Orchestrate everything - the main entry point

```ruby
class NotificationService
  def initialize
    # What you need:
    # - @channels (hash: channel_name => channel_object)
    # - @strategies (hash: strategy_name => strategy_object)
    # - @user_preferences (hash: user_id => UserPreferences)
    # - @delivery_log (array of delivery results)
  end

  def register_channel(name, channel)
    # Add to @channels hash
    # Return self (for method chaining)
  end

  def register_strategy(name, strategy)
    # Add to @strategies hash
    # Return self (for method chaining)
  end

  def set_user_preferences(user_id, preferences)
    # Add to @user_preferences hash
    # Return self (for method chaining)
  end

  def send_notification(notification, channels: [:email], strategy: :immediate)
    # What you need:
    # 1. Get user preferences for notification.recipient
    # 2. Loop through each requested channel
    # 3. Check if user has that channel enabled
    #    - If disabled, print [SKIPPED] and continue
    # 4. Get the channel object from @channels
    #    - If not found, print [ERROR] Unknown channel
    # 5. Get user's preferred strategy (or use provided strategy)
    # 6. Get the strategy object from @strategies
    #    - If not found, print [ERROR] Unknown strategy
    # 7. Call strategy.schedule(notification, channel)
    # 8. Add result to @delivery_log if result exists
  end

  def flush_batches
    # Loop through all strategies
    # Call strategy.flush if it responds to flush
    # Collect results and add to @delivery_log
  end

  attr_reader :delivery_log
end
```

**This is the hardest part!** Take your time here.

---

## STEP 10: Create Demo Usage (5 minutes)
**Goal:** Show your system working end-to-end

```ruby
# At the bottom of your file, add:
if __FILE__ == $0
  # Create service
  service = NotificationService.new

  # Register channels
  service.register_channel(:email, EmailChannel.new)
         .register_channel(:sms, SmsChannel.new)
         .register_channel(:push, PushChannel.new)
         .register_channel(:slack, SlackChannel.new)

  # Register strategies
  service.register_strategy(:immediate, ImmediateDelivery.new)
         .register_strategy(:batched, BatchedDelivery.new(batch_size: 3))

  # Test user preferences
  prefs = UserPreference.new("user2@example.com")
  prefs.disable_channel(:sms)
  prefs.set_delivery_strategy(:batched)
  service.set_user_preferences("user2@example.com", prefs)


  # Test immediate notification
  notification = Notification.new(
    recipient: "user2@example.com",
    message: "Your order has shipped!",
    priority: :high
  )
  service.send_notification(notification, channels: [:email, :sms])


  # Test batched delivery
  3.times do |i|
    notif = Notification.new(
      recipient: "user2@example.com",
      message: "Update ##{i + 1}"
    )
    service.send_notification(notif, channels: [:email])
  end

  service.flush_batches

```

**Run it:** `ruby before.rb`

---

## STEP 11: Write Tests (20 minutes)
**Goal:** Verify everything works

Create a separate test file or add to existing test file:

```ruby
require 'minitest/autorun'
require_relative 'your_file_name'

class NotificationTest < Minitest::Test
  def test_creates_notification
    # Test Notification class
  end
end

class EmailChannelTest < Minitest::Test
  def test_delivers_email
    # Test EmailChannel
  end
end

class ImmediateDeliveryTest < Minitest::Test
  def test_sends_immediately
    # Test ImmediateDelivery
  end
end

class BatchedDeliveryTest < Minitest::Test
  def test_queues_notifications
    # Test batching
  end

  def test_flushes_when_full
    # Test auto-flush
  end
end

class UserPreferencesTest < Minitest::Test
  def test_channel_preferences
    # Test enable/disable
  end
end

class NotificationServiceTest < Minitest::Test
  def test_sends_via_channel
    # Test basic sending
  end

  def test_respects_user_preferences
    # Test preference enforcement
  end

  def test_handles_unknown_channel
    # Test error handling
  end
end
```

**Run tests:** `ruby your_test_file.rb`

---

## STEP 12: Test Extensibility (Optional - 10 minutes)
**Goal:** Prove you can add features without modifying code

```ruby
# Add this to your tests to prove Open/Closed Principle:

class DiscordChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[DISCORD] To: #{notification.recipient}"
    { status: :sent, channel: :discord, recipient: notification.recipient }
  end
end

class ExtensibilityTest < Minitest::Test
  def test_can_add_new_channel
    service = NotificationService.new
    service.register_channel(:discord, DiscordChannel.new)
           .register_strategy(:immediate, ImmediateDelivery.new)

    notif = Notification.new(recipient: "user", message: "test")
    service.send_notification(notif, channels: [:discord])

    assert_equal 1, service.delivery_log.size
  end
end
```

---

## Common Pitfalls to Avoid

1. **Forgetting to return `self` in register methods** → Breaks method chaining
2. **Not handling nil user preferences** → Use `user_prefs&.channel_enabled?`
3. **Forgetting to clear queue after flush** → Notifications send multiple times
4. **Not collecting results from flush** → delivery_log stays empty
5. **Hardcoding channels in service** → Breaks Open/Closed Principle

---

## Success Checklist

- [ ] Notification class with recipient, message, priority
- [ ] DeliveryChannel module with deliver method
- [ ] 4 channel implementations (Email, SMS, Push, Slack)
- [ ] DeliveryStrategy base class
- [ ] ImmediateDelivery implementation
- [ ] BatchedDelivery with queue and flush
- [ ] UserPreferences with enable/disable channels
- [ ] NotificationService with register methods
- [ ] send_notification respects user preferences
- [ ] flush_batches works correctly
- [ ] Demo code runs without errors
- [ ] Tests pass (aim for 15+ tests)
- [ ] Can add new channel without modifying existing code

---

## Time Breakdown

- Steps 1-4: 30 min (Data + Channels)
- Steps 5-7: 25 min (Strategies)
- Step 8: 10 min (Preferences)
- Step 9: 20 min (Service - the hard part)
- Step 10: 5 min (Demo)
- Step 11: 20 min (Tests)
- Step 12: 10 min (Extensibility)
- **Total: ~120 minutes**

---

## Where to Get Help

1. **Stuck on design?** Look at the SOLID principles section in before.rb
2. **Not sure what to implement?** Re-read the component descriptions
3. **Tests failing?** Compare with example usage in before.rb
4. **Really stuck?** Peek at notification_system.rb for hints (but try first!)

Good luck! Remember: Focus on one step at a time, test as you go, and keep SOLID principles in mind.
