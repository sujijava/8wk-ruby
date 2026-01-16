require 'minitest/autorun'
require_relative 'notification_system'

class NotificationTest < Minitest::Test
  def test_creates_notification_with_required_fields
    notif = Notification.new(
      recipient: "user@example.com",
      message: "Test message"
    )

    assert_equal "user@example.com", notif.recipient
    assert_equal "Test message", notif.message
    assert_equal :normal, notif.priority
  end

  def test_creates_notification_with_priority
    notif = Notification.new(
      recipient: "user@example.com",
      message: "Urgent!",
      priority: :high
    )

    assert_equal :high, notif.priority
  end

  def test_accepts_metadata
    notif = Notification.new(
      recipient: "user@example.com",
      message: "Test",
      order_id: 123,
      action: "shipped"
    )

    assert_equal 123, notif.metadata[:order_id]
    assert_equal "shipped", notif.metadata[:action]
  end
end

class EmailChannelTest < Minitest::Test
  def setup
    @channel = EmailChannel.new
    @notification = Notification.new(
      recipient: "test@example.com",
      message: "Test message"
    )
  end

  def test_delivers_notification
    result = @channel.deliver(@notification)

    assert_equal :sent, result[:status]
    assert_equal :email, result[:channel]
    assert_equal "test@example.com", result[:recipient]
  end

  def test_has_name
    assert_equal "email", @channel.name
  end
end

class SmsChannelTest < Minitest::Test
  def setup
    @channel = SmsChannel.new
    @notification = Notification.new(
      recipient: "+1234567890",
      message: "Test SMS"
    )
  end

  def test_delivers_notification
    result = @channel.deliver(@notification)

    assert_equal :sent, result[:status]
    assert_equal :sms, result[:channel]
  end
end

class ImmediateDeliveryTest < Minitest::Test
  def setup
    @strategy = ImmediateDelivery.new
    @channel = EmailChannel.new
    @notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )
  end

  def test_delivers_immediately
    result = @strategy.schedule(@notification, @channel)

    assert_equal :sent, result[:status]
  end
end

class BatchedDeliveryTest < Minitest::Test
  def setup
    @strategy = BatchedDelivery.new(batch_size: 3)
    @channel = EmailChannel.new
  end

  def test_queues_notifications
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @strategy.schedule(notification, @channel)
    assert_equal 1, @strategy.queue.size
  end

  def test_flushes_when_batch_size_reached
    3.times do |i|
      notification = Notification.new(
        recipient: "user#{i}@example.com",
        message: "Test #{i}"
      )
      @strategy.schedule(notification, @channel)
    end

    assert_equal 0, @strategy.queue.size
  end

  def test_manual_flush
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @strategy.schedule(notification, @channel)
    assert_equal 1, @strategy.queue.size

    @strategy.flush
    assert_equal 0, @strategy.queue.size
  end
end

class UserPreferencesTest < Minitest::Test
  def setup
    @prefs = UserPreferences.new("user123")
  end

  def test_default_channels_enabled
    assert @prefs.channel_enabled?(:email)
    assert @prefs.channel_enabled?(:sms)
  end

  def test_can_disable_channel
    @prefs.disable_channel(:sms)
    refute @prefs.channel_enabled?(:sms)
  end

  def test_can_enable_channel
    @prefs.disable_channel(:email)
    @prefs.enable_channel(:email)
    assert @prefs.channel_enabled?(:email)
  end

  def test_default_strategy_is_immediate
    assert_equal :immediate, @prefs.delivery_strategy
  end

  def test_can_set_delivery_strategy
    @prefs.set_delivery_strategy(:batched)
    assert_equal :batched, @prefs.delivery_strategy
  end
end

class NotificationServiceTest < Minitest::Test
  def setup
    @service = NotificationService.new
    @service.register_channel(:email, EmailChannel.new)
           .register_channel(:sms, SmsChannel.new)
           .register_strategy(:immediate, ImmediateDelivery.new)
           .register_strategy(:batched, BatchedDelivery.new(batch_size: 2))
  end

  def test_sends_notification_via_single_channel
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @service.send_notification(notification, channels: [:email])

    assert_equal 1, @service.delivery_log.size
    assert_equal :email, @service.delivery_log.first[:channel]
  end

  def test_sends_notification_via_multiple_channels
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @service.send_notification(notification, channels: [:email, :sms])

    assert_equal 2, @service.delivery_log.size
  end

  def test_respects_user_channel_preferences
    prefs = UserPreferences.new("user@example.com")
    prefs.disable_channel(:sms)
    @service.set_user_preferences("user@example.com", prefs)

    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @service.send_notification(notification, channels: [:email, :sms])

    assert_equal 1, @service.delivery_log.size
    assert_equal :email, @service.delivery_log.first[:channel]
  end

  def test_uses_user_preferred_delivery_strategy
    prefs = UserPreferences.new("user@example.com")
    prefs.set_delivery_strategy(:batched)
    @service.set_user_preferences("user@example.com", prefs)

    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @service.send_notification(notification, channels: [:email])

    # Should be queued, not sent yet
    assert_equal 0, @service.delivery_log.size
  end

  def test_flushes_all_batched_strategies
    prefs = UserPreferences.new("user@example.com")
    prefs.set_delivery_strategy(:batched)
    @service.set_user_preferences("user@example.com", prefs)

    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    @service.send_notification(notification, channels: [:email])
    @service.flush_batches

    assert_equal 1, @service.delivery_log.size
  end

  def test_handles_unknown_channel
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    # Should not raise error, just skip
    @service.send_notification(notification, channels: [:unknown])

    assert_equal 0, @service.delivery_log.size
  end

  def test_handles_unknown_strategy
    notification = Notification.new(
      recipient: "user@example.com",
      message: "Test"
    )

    # Should not raise error, just skip
    @service.send_notification(notification, channels: [:email], strategy: :unknown)

    assert_equal 0, @service.delivery_log.size
  end
end

class ExtensibilityTest < Minitest::Test
  # Custom channel to test extensibility
  class DiscordChannel
    include DeliveryChannel

    def deliver(notification)
      { status: :sent, channel: :discord, recipient: notification.recipient }
    end
  end

  def test_can_add_new_channel_without_modifying_existing_code
    service = NotificationService.new
    service.register_channel(:discord, DiscordChannel.new)
           .register_strategy(:immediate, ImmediateDelivery.new)

    notification = Notification.new(
      recipient: "#general",
      message: "New deployment!"
    )

    service.send_notification(notification, channels: [:discord])

    assert_equal 1, service.delivery_log.size
    assert_equal :discord, service.delivery_log.first[:channel]
  end
end
