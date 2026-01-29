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

# Week 3 Day 5 - Pricing Engine Takeaways

## 1. Order needs TWO totals for sequential rule application
- `base_total` - Original price (never changes, for display to user)
- `discounted_total` - Running total after each rule (gets updated as rules apply)

**Why:** Rules must chain their calculations. Each rule operates on the result of the previous rule, not the original total.

Example:
- Start: $100
- After 10% off: $90 (operate on $100)
- After $5 off: $85 (operate on $90, NOT $100)

## 2. Always use Float for monetary calculations
```ruby
price = 100.0  # ✓ Float
discount = 10.0 / 100.0  # ✓ Float division ensures precision

# Not:
price = 100  # ✗ Integer causes rounding errors
discount = 10 / 100  # ✗ Integer division = 0
```

**Why:** Prevents precision loss in discount calculations. Only round to 2 decimals for display, never in intermediate calculations.


## Roman <-> Integer: Handling Subtractive case - add subtractive cases to values.
  ROMAN_VALUES = {
    "M" => 1000,
    "CM" => 900,   # 900 - subtractive case
    "D" => 500,
    "CD" => 400,   # 400 - subtractive case
    "C" => 100,
    "XC" => 90,    # 90 - subtractive case
    "L" => 50,
    "XL" => 40,    # 40 - subtractive case
    "X" => 10,
    "IX" => 9,     # 9 - subtractive case
    "V" => 5,
    "IV" => 4,     # 4 - subtractive case
    "I" => 1
  }.freeze



  | Method        | Purpose                               | Example                       |
  |---------------|---------------------------------------|-------------------------------|
  | .includes()   | Eager load associations               | .includes(:author, :comments) |
  | .select()     | Choose columns to load                | .select(:id, :title)          |
  | .where()      | Filter records                        | .where(published: true)       |
  | .preload()    | Eager load (always 2 queries)         | .preload(:author)             |
  | .eager_load() | Eager load (always 1 query with JOIN) | .eager_load(:author)          |


# Types of Indexes:
# • Single-column index: CREATE INDEX idx_email ON users(email)
# • Composite index: CREATE INDEX idx_status_created ON orders(status, created_at)
# • Unique index: CREATE UNIQUE INDEX idx_unique_email ON users(email) - just single column index but that column has unique constraint
# • Partial index: CREATE INDEX idx_active_users ON users(email) WHERE active = true


======================================
  # Index 1: Composite index
  QueryAnalyzer.add_index('inventory_logs', ['product_id', 'change_type'])

  # Index 2: Single-column index
  QueryAnalyzer.add_index('inventory_logs', 'product_id')  # ❌ REDUNDANT!

  Why is Index 2 redundant?

  The composite index ['product_id', 'change_type'] can already handle queries that filter by just product_id because it's the leftmost column.