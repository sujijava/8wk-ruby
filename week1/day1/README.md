# Day 1: Blocks, Procs, Lambdas - Retry Mechanism

## The Problem

Build a `with_retry` method that:
1. Accepts a block of code to execute
2. Retries on failure with exponential backoff
3. Takes configurable `max` retries and initial `delay`
4. Re-raises the exception if all retries fail

## Usage Example

```ruby
result = RetryMechanism.with_retry(max: 3, delay: 1) do
  # Some code that might fail
  external_api_call
end
```

## Getting Started

1. Open `retry_mechanism.rb`
2. Implement the `with_retry` method
3. Run tests: `ruby retry_mechanism_test.rb`
4. Uncomment manual tests in the file to see it in action

## Key Learning Points

### Blocks, Procs, Lambdas
- When do you use `yield` vs `block.call`?
- What's the difference between `Proc.new` and `lambda`?
- How does `return` behave differently in each?

### Discussion Points

During a real pair-programming session, expect to discuss:

1. **Exception handling**: Should we catch all exceptions or be selective?
2. **Logging**: How would you add logging for production debugging?
3. **Configurability**: How could you make this work with different exception types?
4. **Testing**: How do you test time-dependent code?
5. **Edge cases**: What if delay is negative? What if max is 0?

## Solution Approach

Start simple, then iterate:

1. **Basic version**: Get something working with `yield`
2. **Add retry logic**: Use a loop with a counter
3. **Add exponential backoff**: Use `sleep` with increasing delays
4. **Handle edge cases**: What about exceptions during sleep?

## Testing

Run the test suite:
```bash
ruby retry_mechanism_test.rb
```

All tests should pass when your implementation is complete.

## Time Box

- **Implementation**: 30-40 minutes
- **Discussion**: 10-15 minutes
- **Reflection**: 5 minutes (write notes on what you learned)

## Real-World Variations

In production, you might also add:
- Custom exception types to retry
- Jitter to prevent thundering herd
- Max elapsed time (not just max attempts)
- Callbacks for monitoring/logging
- Different backoff strategies (linear, fibonacci, decorrelated jitter)

Good luck! Remember to think out loud as you code.
