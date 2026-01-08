require 'minitest/autorun'
require_relative 'retry_mechanism'

class RetryMechanismTest < Minitest::Test
  def setup
    # Reset FlakyAPI state before each test
    FlakyAPI.instance_variable_set(:@attempts, 0)
  end

  def test_successful_execution_without_retry
    result = RetryMechanism.with_retry(max: 3, delay: 0.1) do
      "immediate success"
    end

    assert_equal "immediate success", result
  end

  def test_successful_execution_after_retries
    result = RetryMechanism.with_retry(max: 3, delay: 0.1) do
      FlakyAPI.call(fail_times: 2)
    end

    assert_equal "Success!", result
  end

  def test_raises_exception_after_max_retries
    assert_raises(StandardError) do
      RetryMechanism.with_retry(max: 2, delay: 0.1) do
        FlakyAPI.always_fails
      end
    end
  end

  def test_exponential_backoff_timing
    start_time = Time.now
    attempts = []

    begin
      RetryMechanism.with_retry(max: 3, delay: 0.5) do
        attempts << Time.now
        raise StandardError, "Test error"
      end
    rescue StandardError
      # Expected to fail
    end

    # Should have made 4 attempts total (initial + 3 retries)
    assert_equal 4, attempts.length

    # Check approximate exponential backoff (with some tolerance)
    # Delays should be roughly: 0.5s, 1s, 2s
    if attempts.length >= 3
      delay1 = attempts[1] - attempts[0]
      delay2 = attempts[2] - attempts[1]

      # First delay should be around 0.5s (with 0.2s tolerance)
      assert_in_delta 0.5, delay1, 0.2, "First retry delay should be ~0.5s"

      # Second delay should be roughly double the first
      assert_in_delta 1.0, delay2, 0.3, "Second retry delay should be ~1s"
    end
  end

  def test_returns_block_value
    result = RetryMechanism.with_retry(max: 3, delay: 0.1) do
      42
    end

    assert_equal 42, result
  end
end
