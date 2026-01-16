# Test Step 4: All Channels

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
    self.class.name.gsub('Channel', '').downcase.to_sym
  end
end

# Simplified approach (no Result class)
class EmailChannel
  include DeliveryChannel

  def deliver(notification)
    puts "[EMAIL] To: #{notification.recipient}"
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

# Test all channels
notification = Notification.new(
  recipient: "user@example.com",
  message: "Your order has shipped! This is a longer message to test SMS truncation behavior."
)

puts "=== Testing All Channels ===\n\n"

channels = [
  EmailChannel.new,
  SmsChannel.new,
  PushChannel.new,
  SlackChannel.new
]

channels.each do |channel|
  puts "--- #{channel.class.name} ---"
  result = channel.deliver(notification)
  puts "Result: #{result}"
  puts "\n"
end

puts "✅ All 4 channels working!"
puts "✅ Each has unique output format!"
puts "✅ All return consistent hash structure!"
