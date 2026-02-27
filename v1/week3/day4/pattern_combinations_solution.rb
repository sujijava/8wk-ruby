
# User class

require "pry"

class User
  attr_reader :name, :email, :phone

  def initialize(name, email: nil, phone: nil)
    @name = name
    @email = email
    @phone = phone
  end
end

module Channel
  def deliver 
    raise NotImplementedError
  end

  def name
    self.class.name.gsub(/Channel$/, '').downcase
  end
end

class NullChannel 
  include Channel 
  def deliver 
    puts "null channel can't deliver"
  end
end

class EmailChannel
  include Channel

  def deliver(user, message)
    puts "Sending email to #{user.email}: #{formatted_message(message)}"
    return true
  end

  private

  def formatted_message(message)
      "
      <html>
      <body>
      <img src='logo.png'/>
      #{message}
      <p>Unsubscribe link</p>
      </body>
      </html>"
  end
end


class SMSChannel
  include Channel

  def deliver(user, message)
    puts "Sending SMS to #{user.email}: #{formatted_message(message)}"
    return true
  end

  private

  def formatted_message(message)
    message[0...160]
  end
end


class ChannelFactory
  CHANNEL_STRATEGIES = {
    "email": EmailChannel,
    "sms": SMSChannel,
  }.freeze

  def self.build_channel(channel_type)
    channel_type_sym = channel_type.to_sym
    if CHANNEL_STRATEGIES[channel_type_sym]
      return CHANNEL_STRATEGIES[channel_type_sym].new 
    else
      NullChannel.new
    end
  end
end

class NotificationSystem
  def initialize
    @observers = []
  end

  def send_notification(user, message, channel_type)
    channel = ChannelFactory.build_channel(channel_type)
    channel.deliver(user, message)
  
    notify_observer(user, channel_type, message, "sent")
  end

  def send_urgent_notification(user, message, channel_type)
    message = UrgentMessageDecorator.new(message).to_s
    send_notification(user, message, channel_type)
  end

  def send_tracked_notification(user, message, channel_type, tracking_id)
    message = TrackingMessageDecorator.new(message).to_s
    send_notification(user, message, channel_type)
  end

  def attach_observer(observer)
    @observers << observer
  end

  def detach_observer(observer)
    @observers.delete(observer)
  end

  private 

  def notify_observer(user, channel_type, message, status)
    @observers.each do |observer|
      observer.notify(user, channel_type, message, "sent")
    end
  end
end

class UrgentMessageDecorator
  def initialize(message)
    @message = message  # ✅ Store the wrapped object
  end

  def to_s
    "URGENT: #{@message}"  # ✅ Enhance when converted to string
  end
end

class TrackingMessageDecorator
  def initialize(message)
    @message = message  # ✅ Store the wrapped object
  end

  def to_s
    return "#{message}\n\nTracking: #{tracking_id}"
  end

  private 
  def tracking_id
    "11111"
  end
end

class LoggingObserver
  def notify(user, channel_type, message, status)
    puts "[LOG] #{Time.now} - User: #{user.name}, Channel: #{channel_type}, Status: #{status}"
  end
end

if __FILE__ == $0
  # User with all channels configured
  user = User.new(
    "Alice",
    email: "alice@example.com",
    phone: "+1234567890",
  )

  NotificationSystem.new.send_notification(user, "hello", "email")
  NotificationSystem.new.send_notification(user, "hello", "sms")
  

  user2 = User.new(
    "Alice"
  )
  NotificationSystem.new.send_notification(user2, "hello", "email")
  NotificationSystem.new.send_notification(user2, "hello", "sms")
end