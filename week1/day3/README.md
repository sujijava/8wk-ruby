# Day 3: class_eval & instance_eval - Config DSL

## The Problem

Build a configuration DSL that allows you to define settings using a clean, Ruby-like syntax:

```ruby
Config.define do
  setting :timeout, 30
  setting :max_retries, 3
  setting :api_key, "secret"

  namespace :database do
    setting :host, "localhost"
    setting :port, 5432
  end
end

Config.timeout       # => 30
Config.max_retries   # => 3
Config.database.host # => "localhost"
Config.database.port # => 5432
```

## Requirements

1. Support `Config.define { ... }` block syntax
2. Define settings with `setting :name, value`
3. Support nested namespaces with `namespace :name do ... end`
4. Access settings via `Config.setting_name`
5. Raise error for undefined settings
6. Implement using both `class_eval` and `instance_eval`

## Getting Started

1. Open `config_dsl.rb`
2. Implement the Config DSL
3. Run tests: `ruby config_dsl_test.rb`
4. Understand when to use `class_eval` vs `instance_eval`

## Key Learning Points

### class_eval vs instance_eval

**class_eval:**
- Evaluates code in the context of a CLASS
- Used to define CLASS methods and instance methods
- Changes `self` to the class itself
- Common use: adding methods to classes dynamically

**instance_eval:**
- Evaluates code in the context of an INSTANCE (object)
- Used to define SINGLETON methods
- Changes `self` to the object
- Common use: DSLs, configuration blocks

### The "self" Mystery

Understanding `self` is critical in Ruby metaprogramming:

```ruby
class Foo
  puts self                  # => Foo (the class)

  def bar
    puts self                # => #<Foo:0x...> (the instance)
  end

  class << self
    puts self                # => #<Class:Foo> (singleton class)
  end
end
```

## Discussion Points

During a real pair-programming session, expect to discuss:

1. **self context**: What is `self` at different points?
2. **class_eval vs instance_eval**: When to use each?
3. **DSL design**: How to make it intuitive and readable?
4. **Error handling**: What happens with typos or missing settings?
5. **Namespacing**: How to implement nested configurations?
6. **Real-world examples**: Where have you seen this pattern?

## Solution Approach

Think about these steps:

1. **Start with simple settings**:
   - `Config.define { setting :timeout, 30 }`
   - Store settings in a class variable or constant
   - Create getter methods dynamically

2. **Add the define method**:
   - Use `instance_eval` to evaluate the block in a special context
   - The block should have access to the `setting` method

3. **Implement namespaces**:
   - Create a new Config-like object for each namespace
   - Nest them properly

4. **Add error handling**:
   - Use `method_missing` for undefined settings
   - Provide helpful error messages

## Testing

Run the test suite:
```bash
ruby config_dsl_test.rb
```

Tests cover basic settings, nested namespaces, and error cases.

## Time Box

- **Implementation**: 45-60 minutes
- **Discussion**: 10-15 minutes
- **Reflection**: 5 minutes (write notes on class_eval vs instance_eval)

## Real-World Examples

Where you'll see these patterns:

1. **RSpec**: `describe` and `it` blocks use instance_eval
2. **Rails routes**: `routes.rb` uses instance_eval
3. **Rake**: Task definitions use instance_eval
4. **FactoryBot**: `factory :user do ... end` uses instance_eval
5. **ActiveRecord migrations**: `create_table do |t| ... end`

## Bonus Challenges

If you finish early:

1. Support setting defaults: `setting :timeout, default: 30`
2. Add validation: `setting :port, type: Integer, validates: { min: 1, max: 65535 }`
3. Allow environment-specific configs: `Config.for(:production) { ... }`
4. Implement `Config.to_h` to export as a hash
5. Add `Config.reload!` to reset and redefine

## Key Concepts to Master

1. **instance_eval** - Evaluate block in context of an object
2. **class_eval** - Evaluate block in context of a class
3. **define_singleton_method** - Create class-level accessors
4. **method_missing** - Handle undefined config keys
5. **Blocks and binding** - Understanding block context

Good luck! Remember: DSLs are about making configuration READABLE and INTUITIVE.
