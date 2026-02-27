# Week 1, Day 2: define_method & method_missing
# Exercise: Create a HashProxy that allows accessing hash keys as methods
#
# CONTEXT (Real pair-programming scenario):
# "We're building a configuration system where we want users to access config
# values using dot notation instead of hash syntax. For example:
#   config.database instead of config[:database]
#
# This makes the code more readable and IDE-friendly. We'd like you to implement
# this two ways: using method_missing and using define_method. Then we'll discuss
# the tradeoffs."
#
# REQUIREMENTS:
# 1. Initialize with a hash
# 2. Access hash values using method syntax: proxy.key
# 3. Raise NoMethodError for non-existent keys
# 4. Properly support respond_to?
# 5. Implement both approaches and compare
#
# EXAMPLE USAGE:
#   proxy = HashProxy.new(name: "Alice", age: 30)
#   proxy.name  # => "Alice"
#   proxy.age   # => 30
#   proxy.foo   # => raises NoMethodError
#
# DISCUSSION POINTS (think about these):
# - Which approach is faster? Why?
# - Which gives better stack traces?
# - How does each handle respond_to?
# - When would you use one over the other in production?

# Approach 1: Using method_missing
class HashProxyMethodMissing
  def initialize(hash)
    @hash = hash
  end

  def method_missing(method_name, *args, &block)
    return @hash[method_name] if @hash.key?(method_name)
    super
  end

  def respond_to_missing?(method_name, include_private = false)
    @hash.key?(method_name)
  end
end

# Approach 2: Using define_method
class HashProxyDefineMethod
  def initialize(hash)
    @hash = hash

    @hash.each do |key, value|
      define_singleton_method(key) do
        value
      end
    end

    define_singleton_method(:respond_to?) do |method_name, include_private = false|
      @hash.key?(method_name) || super(method_name, include_private)
    end
  end
end

# Performance comparison helper
class HashProxyBenchmark
  def self.compare(iterations = 100_000)
    require 'benchmark'

    hash = { name: "Alice", age: 30, city: "NYC" }
    proxy_mm = HashProxyMethodMissing.new(hash)
    proxy_dm = HashProxyDefineMethod.new(hash)

    puts "Running #{iterations} iterations...\n\n"

    Benchmark.bm(20) do |x|
      x.report("method_missing:") do
        iterations.times { proxy_mm.name }
      end

      x.report("define_method:") do
        iterations.times { proxy_dm.name }
      end
    end
  end
end

# Manual testing examples (uncomment to test):
if __FILE__ == $0
  puts "Testing HashProxy implementations...\n\n"

  # Test method_missing version
  puts "=== method_missing approach ==="
  proxy = HashProxyMethodMissing.new(database: 'postgres', timeout: 30)
  puts "database: #{proxy.database}"
  puts "timeout: #{proxy.timeout}"
  puts "respond_to?(:database): #{proxy.respond_to?(:database)}"
  puts "respond_to?(:unknown): #{proxy.respond_to?(:unknown)}"
  
  begin
    proxy.unknown
  rescue NoMethodError => e
    puts "Caught NoMethodError: #{e.message}"
  end

  # Test define_method version
  puts "\n=== define_method approach ==="
  proxy2 = HashProxyDefineMethod.new(database: 'postgres', timeout: 30)
  puts "database: #{proxy2.database}"
  puts "timeout: #{proxy2.timeout}"
  puts "respond_to?(:database): #{proxy2.respond_to?(:database)}"
  
  begin
    proxy2.unknown
  rescue NoMethodError => e
    puts "Caught NoMethodError: #{e.message}"
  end

  # Performance comparison
  puts "\n=== Performance Comparison ==="
  HashProxyBenchmark.compare
end
