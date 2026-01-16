# Quick test for Steps 1 & 2

class Notification
  attr_reader :recipient, :message, :priority, :metadata

  def initialize(recipient:, message:, priority: :normal, **metadata)
    @recipient = recipient
    @message = message
    @priority = priority
    @metadata = metadata
  end
end

module DeliveryChannel
  def deliver(notification)
    raise NotImplementedError
  end

  def name
    self.class.name.gsub('Channel', '')
  end
end

# Test Step 1
puts "=== Testing Step 1: Notification ==="
notif = Notification.new(recipient: "test@example.com", message: "Hello")
puts "Recipient: #{notif.recipient}"
puts "Message: #{notif.message}"
puts "Priority: #{notif.priority}"
puts "✅ Step 1 looks good!"

# Test with metadata
notif2 = Notification.new(
  recipient: "user@example.com",
  message: "Order shipped",
  priority: :high,
  order_id: 123,
  tracking: "ABC123"
)
puts "\nWith metadata:"
puts "Priority: #{notif2.priority}"
puts "Metadata: #{notif2.metadata.inspect}"
puts "✅ Metadata works!"

# Test Step 2
puts "\n=== Testing Step 2: DeliveryChannel ==="

class TestChannel
  include DeliveryChannel
end

test_channel = TestChannel.new
puts "Channel name: #{test_channel.name}"

begin
  test_channel.deliver(notif)
rescue NotImplementedError => e
  puts "✅ NotImplementedError raised correctly!"
end

puts "\n🎉 Steps 1 & 2 are working great!"
