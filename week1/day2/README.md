# Day 2: define_method & method_missing - Hash Proxy

## Real Interview Context

This is based on actual pair-programming questions from companies like:
- **Stripe** - Building flexible configuration objects
- **GitHub** - Internal DSL for feature flags
- **Shopify** - Dynamic attribute access patterns

## The Problem

Create a `HashProxy` class that allows accessing hash keys as methods:

```ruby
config = HashProxy.new(database: 'postgres', timeout: 30)
config.database  # => 'postgres'
config.timeout   # => 30
config.unknown   # => raises NoMethodError
```

**Then implement it TWO ways:**
1. Using `method_missing`
2. Using `define_method`

## Requirements

1. Initialize with a hash
2. Access hash values using method calls
3. Raise `NoMethodError` for keys that don't exist
4. Support `respond_to?` correctly
5. Be prepared to discuss tradeoffs

## Getting Started

1. Open `hash_proxy.rb`
2. Implement both approaches
3. Run tests: `ruby hash_proxy_test.rb`
4. Compare the two implementations

## Key Learning Points

### method_missing vs define_method

**method_missing:**
- Called when a method doesn't exist
- Dynamically handles ANY method call
- Slower (Ruby searches method lookup chain first)
- More flexible (can handle infinite methods)

**define_method:**
- Creates actual methods
- Faster (methods exist in lookup chain)
- Less flexible (must know methods upfront)
- Better stack traces and introspection

## Interview Discussion Points

During a real pair-programming session, expect to discuss:

1. **Performance**: Why is `define_method` faster?
2. **Debugging**: Which approach gives better error messages?
3. **Introspection**: What happens with `methods`, `respond_to?`?
4. **Use cases**: When would you choose one over the other?
5. **Ghost methods**: What are they? What problems can they cause?
6. **Alternatives**: What about using `Struct` or `OpenStruct`?

## Solution Approach

Start with `method_missing`, then refactor:

1. **method_missing version**:
   - Override `method_missing`
   - Check if key exists in hash
   - Override `respond_to_missing?` for proper introspection

2. **define_method version**:
   - Define methods in `initialize`
   - Use `define_singleton_method` for instance-specific methods
   - Compare performance and behavior

## Testing

Run the test suite:
```bash
ruby hash_proxy_test.rb
```

Tests cover both implementations and edge cases.

## Time Box

- **Implementation**: 30-40 minutes
- **Discussion**: 10-15 minutes
- **Reflection**: 5 minutes (write notes on tradeoffs)

## Real-World Examples

Where you'll see these patterns:

1. **Rails**: `method_missing` in ActiveRecord for dynamic finders (legacy)
2. **RSpec**: `method_missing` for `should` syntax
3. **Hashie**: `Hashie::Mash` uses similar patterns
4. **Config gems**: Many use `method_missing` for dot notation

## Bonus Challenges

If you finish early:

1. Support hash assignment: `config.timeout = 60`
2. Handle nested hashes: `config.db.host`
3. Add `method_missing` call tracking for debugging
4. Implement a hybrid approach (define common methods, fall back to `method_missing`)

Good luck! Remember to discuss tradeoffs as you code.
