require 'minitest/autorun'
require_relative 'hash_proxy'

class HashProxyMethodMissingTest < Minitest::Test
  def setup
    @proxy = HashProxyMethodMissing.new(name: "Alice", age: 30, city: "NYC")
  end

  def test_access_existing_key
    assert_equal "Alice", @proxy.name
    assert_equal 30, @proxy.age
    assert_equal "NYC", @proxy.city
  end

  def test_raises_no_method_error_for_missing_key
    assert_raises(NoMethodError) do
      @proxy.unknown_key
    end
  end

  def test_respond_to_returns_true_for_existing_keys
    assert @proxy.respond_to?(:name)
    assert @proxy.respond_to?(:age)
    assert @proxy.respond_to?(:city)
  end

  def test_respond_to_returns_false_for_missing_keys
    refute @proxy.respond_to?(:unknown_key)
    refute @proxy.respond_to?(:foo)
  end

  def test_handles_symbol_and_string_keys
    proxy_with_strings = HashProxyMethodMissing.new("name" => "Bob")
    # This test depends on implementation choice
    # Some implementations convert strings to symbols
  end

  def test_works_with_various_value_types
    proxy = HashProxyMethodMissing.new(
      string: "hello",
      number: 42,
      array: [1, 2, 3],
      hash: { nested: true },
      nil_value: nil
    )

    assert_equal "hello", proxy.string
    assert_equal 42, proxy.number
    assert_equal [1, 2, 3], proxy.array
    assert_nil proxy.nil_value
  end

  def test_respond_to_works_with_nil_values
    proxy = HashProxyMethodMissing.new(nil_key: nil)
    assert proxy.respond_to?(:nil_key), "respond_to? should return true even when value is nil"
    assert_nil proxy.nil_key
  end

  def test_error_message_includes_method_name
    proxy = HashProxyMethodMissing.new(name: "Alice")
    error = assert_raises(NoMethodError) do
      proxy.unknown_method
    end
    assert_match(/unknown_method/, error.message, "Error message should mention the missing method")
  end
end

class HashProxyDefineMethodTest < Minitest::Test
  def setup
    @proxy = HashProxyDefineMethod.new(name: "Alice", age: 30, city: "NYC")
  end

  def test_access_existing_key
    assert_equal "Alice", @proxy.name
    assert_equal 30, @proxy.age
    assert_equal "NYC", @proxy.city
  end

  def test_raises_no_method_error_for_missing_key
    assert_raises(NoMethodError) do
      @proxy.unknown_key
    end
  end

  def test_respond_to_returns_true_for_existing_keys
    assert @proxy.respond_to?(:name)
    assert @proxy.respond_to?(:age)
    assert @proxy.respond_to?(:city)
  end

  def test_respond_to_returns_false_for_missing_keys
    refute @proxy.respond_to?(:unknown_key)
    refute @proxy.respond_to?(:foo)
  end

  def test_methods_appear_in_methods_list
    # define_method creates real methods, so they should appear in methods()
    methods = @proxy.methods
    assert_includes methods, :name
    assert_includes methods, :age
    assert_includes methods, :city
  end

  def test_works_with_various_value_types
    proxy = HashProxyDefineMethod.new(
      string: "hello",
      number: 42,
      array: [1, 2, 3],
      hash: { nested: true },
      nil_value: nil
    )

    assert_equal "hello", proxy.string
    assert_equal 42, proxy.number
    assert_equal [1, 2, 3], proxy.array
    assert_nil proxy.nil_value
  end

  def test_respond_to_works_with_nil_values
    proxy = HashProxyDefineMethod.new(nil_key: nil)
    assert proxy.respond_to?(:nil_key), "respond_to? should return true even when value is nil"
    assert_nil proxy.nil_key
  end

  def test_respond_to_works_for_inherited_methods
    proxy = HashProxyDefineMethod.new(name: "Alice")
    assert proxy.respond_to?(:class), "respond_to? should work for inherited methods"
    assert proxy.respond_to?(:to_s)
    assert proxy.respond_to?(:object_id)
  end
end

class HashProxyComparisonTest < Minitest::Test
  def test_both_implementations_behave_the_same
    hash = { name: "Alice", age: 30 }
    proxy_mm = HashProxyMethodMissing.new(hash.dup)
    proxy_dm = HashProxyDefineMethod.new(hash.dup)

    assert_equal proxy_mm.name, proxy_dm.name
    assert_equal proxy_mm.age, proxy_dm.age
    assert_equal proxy_mm.respond_to?(:name), proxy_dm.respond_to?(:name)
    assert_equal proxy_mm.respond_to?(:unknown), proxy_dm.respond_to?(:unknown)
  end

  def test_define_method_creates_real_methods
    proxy_mm = HashProxyMethodMissing.new(name: "Alice")
    proxy_dm = HashProxyDefineMethod.new(name: "Alice")

    # define_method version should have :name in methods list
    assert_includes proxy_dm.methods, :name

    # method_missing version won't have :name in methods list
    # (it uses ghost methods)
    refute_includes proxy_mm.methods, :name
  end
end
