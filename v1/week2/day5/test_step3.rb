# Test Step 3: EmailChannel

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

# Your approach with Result class
class Result
  attr_accessor :status, :channel, :recipient
  def initialize
    @status
    @channel
    @recipient
  end
end

class EmailChannelYourWay
  include DeliveryChannel

  def initialize
    @result = Result.new
  end

  def deliver(notification)
    puts "#{name} delivered"
    @result.status = :sent
    @result.channel = :email
    @result.recipient = notification.recipient

    return @result
  end
end

# Recommended approach with hash
class EmailChannelRecommended
  include DeliveryChannel

  def deliver(notification)
    puts "[EMAIL] To: #{notification.recipient}"
    puts "        Subject: Notification"
    puts "        Body: #{notification.message}"

    { status: :sent, channel: :email, recipient: notification.recipient }
  end
end

# Test both
notification = Notification.new(
  recipient: "user@example.com",
  message: "Your order has shipped!"
)

puts "=== Your Way (with Result class) ==="
channel1 = EmailChannelYourWay.new
result1 = channel1.deliver(notification)
puts "Result class: #{result1.class}"
puts "Status: #{result1.status}"
puts "Channel: #{result1.channel}"
puts "Recipient: #{result1.recipient}"

puts "\n=== Recommended Way (with Hash) ==="
channel2 = EmailChannelRecommended.new
result2 = channel2.deliver(notification)
puts "\nResult class: #{result2.class}"
puts "Status: #{result2[:status]}"
puts "Channel: #{result2[:channel]}"
puts "Recipient: #{result2[:recipient]}"

puts "\n=== Comparison ==="
puts "Your way works: #{result1.status == :sent ? '✅' : '❌'}"
puts "Recommended way works: #{result2[:status] == :sent ? '✅' : '❌'}"
puts "\nBoth work! But hash is simpler (no extra Result class needed)"
