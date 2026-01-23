# Daily Learning Takeaways

## Day: 2026-01-22

### 1. Instance Variables vs Constants in Class Methods
**Problem:** Can't access instance variables (`@var`) from class methods
```ruby
# ❌ WRONG
class ChannelFactory
  @channel_strategies = { email: EmailChannel }
  def self.build_channel(type)
    @channel_strategies[type]  # Returns nil!
  end
end

# ✅ CORRECT
class ChannelFactory
  CHANNEL_STRATEGIES = { email: EmailChannel }.freeze
  def self.build_channel(type)
    CHANNEL_STRATEGIES[type]&.new
  end
end
```

### 2. Decorator Pattern: `initialize` Returns Object, Not Value
**Problem:** `return` in `initialize` does nothing
```ruby
# ❌ WRONG
class UrgentMessageDecorator
  def initialize(message)
    return "URGENT: #{message}"  # Ignored!
  end
end

# ✅ CORRECT
class UrgentMessageDecorator
  def initialize(message)
    @message = message  # Store wrapped object
  end

  def to_s
    "URGENT: #{@message}"  # Enhance on output
  end
end
```

### 3. Null Object Pattern: Handle Missing User Data, Not Invalid Types
**Purpose:** Gracefully handle users without contact info
```ruby
# ✅ CORRECT
class ChannelFactory
  def self.build_channel(user, channel_type)
    return NullChannel.new unless user_has_channel?(user, channel_type)
    CHANNEL_STRATEGIES[channel_type.to_sym]&.new || NullChannel.new
  end

  def self.user_has_channel?(user, channel_type)
    case channel_type.to_sym
    when :email then !user.email.nil? && !user.email.empty?
    when :sms then !user.phone.nil? && !user.phone.empty?
    else false
    end
  end
end
```

**Key:** Null Object prevents errors when user data is incomplete, not when channel type is unknown.
