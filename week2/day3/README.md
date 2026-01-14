# Week 2, Day 3: Dependency Injection + Service Objects

## Objective
Learn two critical patterns for writing testable, maintainable code:
1. **Dependency Injection** - Make classes testable by injecting dependencies instead of hardcoding them
2. **Service Objects** - Extract complex business logic from controllers into reusable, testable services

## Part 1: Dependency Injection

### The Problem

Code with hardcoded dependencies is:
- **Impossible to test** without hitting real APIs
- **Tightly coupled** to specific implementations
- **Difficult to change** when requirements evolve
- **Hard to reason about** due to hidden dependencies

### Bad Example (Hardcoded Dependencies)
```ruby
class WeatherService
  def get_forecast(city)
    # Hardcoded HTTParty - can't test without hitting real API
    response = HTTParty.get("https://api.weather.com/forecast?city=#{city}")
    JSON.parse(response.body)
  end
end
```

### Good Example (Dependency Injection)
```ruby
class WeatherService
  def initialize(http_client)
    @http_client = http_client
  end

  def get_forecast(city)
    response = @http_client.get("https://api.weather.com/forecast?city=#{city}")
    JSON.parse(response.body)
  end
end

# In tests, inject a mock client
mock_client = double('http_client')
service = WeatherService.new(http_client: mock_client)
```

### Your Task: Part 1

Refactor `api_client_before.rb` to:
1. Remove all hardcoded `HTTParty.get` calls
2. Inject the HTTP client as a dependency
3. Make it fully testable without external API calls
4. Support swapping HTTP clients (HTTParty, Faraday, Net::HTTP)

## Part 2: Service Objects

### The Problem

"Fat controllers" are a common Rails anti-pattern:
- **Business logic mixed with HTTP concerns**
- **Hard to test** (need to simulate requests/responses)
- **Difficult to reuse** (logic trapped in controller)
- **Violates SRP** (one controller action does too much)

### Fat Controller Anti-Pattern
```ruby
class OrdersController < ApplicationController
  def create
    # Validation logic
    unless params[:email].present?
      render json: { error: 'Email required' }, status: 422
      return
    end

    # Business logic
    order = Order.new(order_params)
    order.calculate_totals
    order.apply_discounts

    # Payment processing
    if charge_credit_card(params[:card_token], order.total)
      order.save!

      # Email sending
      OrderMailer.confirmation(order).deliver_now

      # Inventory management
      order.items.each do |item|
        item.product.decrement!(:stock)
      end

      # Analytics
      track_conversion(order)

      render json: order, status: 201
    else
      render json: { error: 'Payment failed' }, status: 402
    end
  end
end
```

### Service Object Pattern
```ruby
class OrdersController < ApplicationController
  def create
    result = CreateOrderService.call(params: order_params)

    if result.success?
      render json: result.order, status: 201
    else
      render json: { error: result.error }, status: result.status_code
    end
  end
end

class CreateOrderService
  def self.call(params:)
    new(params: params).call
  end

  def initialize(params:)
    @params = params
  end

  def call
    # All business logic extracted here
    # Testable without controller
    # Reusable from other contexts (jobs, console, etc.)
  end
end
```

### Your Task: Part 2

Refactor `fat_controller_before.rb` to:
1. Extract business logic into service objects
2. Keep controller thin (5-10 lines)
3. Make services testable in isolation
4. Use dependency injection where appropriate
5. Return result objects (not booleans)

## Design Patterns to Use

### 1. Constructor Injection (Most Common)
```ruby
class OrderService
  def initialize(payment_gateway:, mailer:)
    @payment_gateway = payment_gateway
    @mailer = mailer
  end
end
```

### 2. Method Injection
```ruby
class OrderService
  def process(order, payment_gateway:)
    payment_gateway.charge(order.total)
  end
end
```

### 3. Default Dependencies
```ruby
class OrderService
  def initialize(payment_gateway: StripeGateway.new)
    @payment_gateway = payment_gateway
  end
end
```

### 4. Service Object Pattern
```ruby
class CreateOrderService
  def self.call(**args)
    new(**args).call
  end

  def call
    # Business logic here
    ServiceResult.new(success: true, order: @order)
  end
end

class ServiceResult
  attr_reader :order, :error, :status_code

  def initialize(success:, order: nil, error: nil, status_code: nil)
    @success = success
    @order = order
    @error = error
    @status_code = status_code
  end

  def success?
    @success
  end
end
```

## Key Principles

### Dependency Injection Benefits
1. **Testability** - Inject mocks/stubs in tests
2. **Flexibility** - Swap implementations easily
3. **Explicit dependencies** - Clear what the class needs
4. **Reduced coupling** - Depend on interfaces, not implementations

### Service Object Benefits
1. **Single Responsibility** - Each service does one thing
2. **Testability** - Test business logic without controllers
3. **Reusability** - Call from anywhere (controllers, jobs, console)
4. **Clarity** - Clear naming: `CreateOrderService`, `ChargeCardService`

## Questions to Consider

1. Should all dependencies be injected, or just external ones?
2. When should you use service objects vs. model methods?
3. How do you handle service objects that need many dependencies?
4. What should service objects return? (booleans, result objects, exceptions?)
5. Should service objects be instantiated or use class methods?

## Testing Your Work

### Part 1 - API Client
```bash
ruby api_client_before.rb      # See the problem
ruby api_client_after.rb       # See your solution
```

### Part 2 - Fat Controller
```bash
ruby fat_controller_before.rb  # See the problem
ruby fat_controller_after.rb   # See your solution
```

## Time Allocation (90-120 min)

**Part 1: Dependency Injection (40-50 min)**
- 10 min: Understand the current code
- 20 min: Refactor with dependency injection
- 10 min: Add tests demonstrating testability

**Part 2: Service Objects (50-70 min)**
- 15 min: Identify all responsibilities in the fat controller
- 25 min: Extract into service objects
- 10 min: Wire everything together
- 10 min: Test the refactored code

## Success Criteria

### Part 1
- No hardcoded external dependencies
- Can inject mock HTTP client in tests
- Easy to swap HTTP libraries
- All tests pass without making real API calls

### Part 2
- Controller actions are 5-10 lines maximum
- Business logic extracted into services
- Services are testable without controller/request context
- Service objects have clear names and single responsibilities
- Result objects provide detailed success/failure information

## Bonus Challenges

1. **Create a service registry** - Centrally manage service dependencies
2. **Add transaction support** - Rollback on failure
3. **Implement circuit breaker pattern** - Handle API failures gracefully
4. **Add request/response logging** - Inject a logger
5. **Create a service pipeline** - Chain multiple services together
6. **Add caching layer** - Inject cache as dependency

## Real-World Context

In senior interviews, you'll be judged on:
- **Do you reach for dependency injection naturally?**
- **Can you identify when a controller is too fat?**
- **Do you know when to extract a service object?**
- **Can you test complex logic in isolation?**
- **Do you understand the tradeoffs?** (over-abstraction vs. coupling)

These patterns appear everywhere in Rails codebases:
- Payment processing (Stripe, PayPal adapters)
- External APIs (wrapping third-party services)
- Complex workflows (order creation, user registration)
- Background jobs (services make job code cleaner)
- Testing (mocking external services)

## Common Pitfalls to Avoid

1. **Over-injection** - Don't inject everything, use judgment
2. **Anemic services** - Services should encapsulate logic, not just call models
3. **God services** - Keep services focused, don't create `OrderService` that does 20 things
4. **Ignoring defaults** - Provide sensible defaults for dependencies
5. **No result objects** - Don't return booleans from complex operations
6. **Service explosion** - Not every operation needs a service object
