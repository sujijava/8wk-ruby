# Week 1, Day 3: class_eval & instance_eval
# Exercise: Build a simple config DSL
#
# CONTEXT (Real pair-programming scenario):
# "We need a clean way for developers to configure our application.
# Instead of ugly YAML files, we want a Ruby DSL that's readable and
# type-safe. Something like:
#
#   Config.define do
#     setting :timeout, 30
#     setting :api_key, 'secret'
#
#     namespace :database do
#       setting :host, 'localhost'
#       setting :port, 5432
#     end
#   end
#
# Then access it with: Config.timeout, Config.database.host
# Can you build this? We'll discuss class_eval vs instance_eval as we go."
#
# REQUIREMENTS:
# 1. Config.define { ... } block syntax
# 2. setting :name, value inside the block
# 3. Config.setting_name to retrieve values
# 4. namespace :name do ... end for nested configs
# 5. Raise NoMethodError for undefined settings
# 6. Support respond_to? properly
#
# EXAMPLE USAGE:
#   Config.define do
#     setting :timeout, 30
#     setting :max_retries, 3
#
#     namespace :database do
#       setting :host, "localhost"
#       setting :port, 5432
#     end
#   end
#
#   Config.timeout          # => 30
#   Config.max_retries      # => 3
#   Config.database.host    # => "localhost"
#   Config.database.port    # => 5432
#   Config.unknown          # => raises NoMethodError
#
# DISCUSSION POINTS (think about these):
# - Why use instance_eval for the define block?
# - When would you use class_eval instead?
# - What is 'self' at different points in the code?
# - How does this compare to YAML/JSON config?
# - What are the security implications of eval?

require "pry"

class Config
  # Class-level storage for settings
  @settings = {}

  class << self
    attr_accessor :settings

    def define(&block)
      class_eval(&block)
    end

    def setting(name, value)
      @settings[name] = value
    end

    def namespace(name, &block)
      nested_hash = ConfigBuilder.new.namespace(name, &block)
      
      @settings[name] = nested_hash
      binding.pry
    end

    # Handle undefined settings
    def method_missing(method_name, *args, &block)
      if @settings.key?(method_name)
        define_singleton_method(method_name) do 
          @settings[method_name]
        end
        return @settings[method_name]
      else
        raise NoMethodError, "no method"
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @setting.key?(method_name)
    end

    # Utility method to reset configuration (useful for testing)
    def reset!
      @settings = {}
      # TODO: Remove dynamically defined methods
      # This is tricky! You might need to track which methods you've defined
    end
  end
end

class Settings
end

# Alternative approach using a separate context object
# This can make the implementation cleaner
class ConfigBuilder
  def initialize()
    @config = Config
  end

  def setting(name, value)
    @config.name = value
  end

  def namespace(name, &block)
    instance_eval(&block)
    return @config
  end
end

# Manual testing (uncomment to test):
if __FILE__ == $0
  puts "Testing Config DSL...\n\n"

  # Define configuration
  Config.define do
    setting :timeout, 30
    setting :max_retries, 3
    setting :api_key, "secret_key_123"

    namespace :database do
      setting :host, "localhost"
      setting :port, 5432
      setting :username, "admin"
    end

    # namespace :redis do
    #   setting :host, "127.0.0.1"
    #   setting :port, 6379
    # end
  end

  # Test accessing settings
  puts "=== Top-level settings ==="
  puts "Config.timeout: #{Config.timeout}"
  puts "Config.max_retries: #{Config.max_retries}"
  puts "Config.api_key: #{Config.api_key}"

  puts "=== Nested settings ==="
  puts "Config.database.host: #{Config.database.host}"
  # puts "Config.database.port: #{Config.database.port}"
  # puts "Config.database.username: #{Config.database.username}"
  # puts

  # puts "Config.redis.host: #{Config.redis.host}"
  # puts "Config.redis.port: #{Config.redis.port}"
  # puts

  # puts "=== respond_to? ==="
  # puts "Config.respond_to?(:timeout): #{Config.respond_to?(:timeout)}"
  # puts "Config.respond_to?(:unknown): #{Config.respond_to?(:unknown)}"
  # puts "Config.database.respond_to?(:host): #{Config.database.respond_to?(:host)}"
  # puts

  # puts "=== Error handling ==="
  # begin
  #   Config.undefined_setting
  # rescue NoMethodError => e
  #   puts "Caught error for undefined setting: #{e.message}"
  # end
end
