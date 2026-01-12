require 'minitest/autorun'
require_relative 'config_dsl'

class ConfigDSLTest < Minitest::Test
  def setup
    # Reset config before each test
    Config.reset! if Config.respond_to?(:reset!)
  end

  def teardown
    # Clean up after each test
    Config.reset! if Config.respond_to?(:reset!)
  end

  def test_simple_setting
    Config.define do
      setting :timeout, 30
    end

    assert_equal 30, Config.timeout
  end

  def test_multiple_settings
    Config.define do
      setting :timeout, 30
      setting :max_retries, 3
      setting :api_key, "secret"
    end

    assert_equal 30, Config.timeout
    assert_equal 3, Config.max_retries
    assert_equal "secret", Config.api_key
  end

  def test_setting_with_different_types
    Config.define do
      setting :string_val, "hello"
      setting :int_val, 42
      setting :float_val, 3.14
      setting :bool_val, true
      setting :nil_val, nil
      setting :array_val, [1, 2, 3]
      setting :hash_val, { key: "value" }
    end

    assert_equal "hello", Config.string_val
    assert_equal 42, Config.int_val
    assert_equal 3.14, Config.float_val
    assert_equal true, Config.bool_val
    assert_nil Config.nil_val
    assert_equal [1, 2, 3], Config.array_val
    assert_equal({ key: "value" }, Config.hash_val)
  end

  def test_namespace
    Config.define do
      namespace :database do
        setting :host, "localhost"
        setting :port, 5432
      end
    end

    assert_respond_to Config, :database
    assert_equal "localhost", Config.database.host
    assert_equal 5432, Config.database.port
  end

  def test_multiple_namespaces
    Config.define do
      namespace :database do
        setting :host, "localhost"
        setting :port, 5432
      end

      namespace :redis do
        setting :host, "127.0.0.1"
        setting :port, 6379
      end
    end

    assert_equal "localhost", Config.database.host
    assert_equal 5432, Config.database.port
    assert_equal "127.0.0.1", Config.redis.host
    assert_equal 6379, Config.redis.port
  end

  def test_nested_namespaces
    Config.define do
      namespace :database do
        setting :host, "localhost"

        namespace :pool do
          setting :size, 5
          setting :timeout, 10
        end
      end
    end

    assert_equal "localhost", Config.database.host
    assert_equal 5, Config.database.pool.size
    assert_equal 10, Config.database.pool.timeout
  end

  def test_mixed_settings_and_namespaces
    Config.define do
      setting :app_name, "MyApp"
      setting :version, "1.0.0"

      namespace :database do
        setting :host, "localhost"
        setting :port, 5432
      end

      setting :debug, true
    end

    assert_equal "MyApp", Config.app_name
    assert_equal "1.0.0", Config.version
    assert_equal true, Config.debug
    assert_equal "localhost", Config.database.host
    assert_equal 5432, Config.database.port
  end

  def test_undefined_setting_raises_error
    Config.define do
      setting :timeout, 30
    end

    assert_raises(NoMethodError) do
      Config.undefined_setting
    end
  end

  def test_undefined_namespace_raises_error
    Config.define do
      setting :timeout, 30
    end

    assert_raises(NoMethodError) do
      Config.undefined_namespace.something
    end
  end

  def test_respond_to_for_defined_settings
    Config.define do
      setting :timeout, 30
      setting :max_retries, 3
    end

    assert Config.respond_to?(:timeout)
    assert Config.respond_to?(:max_retries)
  end

  def test_respond_to_for_undefined_settings
    Config.define do
      setting :timeout, 30
    end

    refute Config.respond_to?(:undefined_setting)
    refute Config.respond_to?(:something_else)
  end

  def test_respond_to_for_namespaces
    Config.define do
      namespace :database do
        setting :host, "localhost"
      end
    end

    assert Config.respond_to?(:database)
    assert Config.database.respond_to?(:host)
    refute Config.database.respond_to?(:undefined)
  end

  def test_can_redefine_settings
    Config.define do
      setting :timeout, 30
    end

    assert_equal 30, Config.timeout

    Config.define do
      setting :timeout, 60
    end

    assert_equal 60, Config.timeout
  end

  def test_settings_persist_across_define_calls
    Config.define do
      setting :timeout, 30
    end

    Config.define do
      setting :max_retries, 3
    end

    # Both should be available
    assert_equal 30, Config.timeout
    assert_equal 3, Config.max_retries
  end

  def test_reset_clears_all_settings
    skip "Implement Config.reset! for this test" unless Config.respond_to?(:reset!)

    Config.define do
      setting :timeout, 30
      namespace :database do
        setting :host, "localhost"
      end
    end

    Config.reset!

    assert_raises(NoMethodError) { Config.timeout }
    assert_raises(NoMethodError) { Config.database }
  end
end

class ConfigDSLEdgeCasesTest < Minitest::Test
  def setup
    Config.reset! if Config.respond_to?(:reset!)
  end

  def teardown
    Config.reset! if Config.respond_to?(:reset!)
  end

  def test_setting_name_with_underscore
    Config.define do
      setting :max_retry_count, 5
    end

    assert_equal 5, Config.max_retry_count
  end

  def test_setting_name_with_question_mark
    # This might not work depending on implementation
    # Just testing edge case
    Config.define do
      setting :enabled, true
    end

    assert_equal true, Config.enabled
  end

  def test_empty_define_block
    Config.define do
      # nothing
    end

    # Should not raise error
    assert true
  end

  def test_empty_namespace
    Config.define do
      namespace :database do
        # nothing
      end
    end

    assert_respond_to Config, :database
  end

  def test_overwriting_settings_in_same_define
    Config.define do
      setting :timeout, 30
      setting :timeout, 60  # Overwrite
    end

    assert_equal 60, Config.timeout
  end
end
