# Week 2, Day 1: Single Responsibility Principle (SRP)

## Objective
Refactor a monolithic `OrderProcessor` class that violates the Single Responsibility Principle by handling too many different concerns.

## The Problem

The `OrderProcessor` class in `order_processor_before.rb` has **at least 6 different responsibilities**:

1. **Order Validation** - Validating customer info, items, addresses
2. **Payment Processing** - Charging credit cards, handling payment errors
3. **Inventory Management** - Checking stock, updating quantities, low stock alerts
4. **Shipping Calculation** - Computing costs, delivery dates, tracking
5. **Email Notifications** - Sending confirmation and shipping emails
6. **Logging & Analytics** - Recording orders, tracking metrics

## Your Task

Create `order_processor_after.rb` with a refactored design that:

1. **Extracts each responsibility into separate classes**
2. **Makes the main `OrderProcessor` orchestrate the workflow**
3. **Improves testability** - each component can be tested in isolation
4. **Follows dependency injection** - don't hardcode dependencies
5. **Maintains the same external API** - the caller shouldn't need to change

## Design Hints

Consider creating classes like:
- `OrderValidator` - handles all validation logic
- `PaymentProcessor` - manages payment gateway interactions
- `InventoryManager` - tracks and updates stock levels
- `ShippingCalculator` - computes shipping costs and dates
- `NotificationService` - handles all email communications
- `OrderLogger` / `AnalyticsTracker` - manages logging and metrics

The refactored `OrderProcessor` should become a **coordinator** that delegates to these services.

## Questions to Consider

1. How will you handle errors from different services?
2. Should all services be injected as dependencies, or can some be instantiated internally?
3. How will you make this testable? (Hint: dependency injection)
4. What happens if the payment succeeds but inventory update fails?
5. Which operations need to happen in a specific order?

## Testing Your Work

Run the original code:
```bash
ruby order_processor_before.rb
```

Then implement your refactored version and verify it produces the same results:
```bash
ruby order_processor_after.rb
```

## Time Allocation (45-60 min)

- **15 min:** Identify all responsibilities and plan class extraction
- **30 min:** Implement the refactored classes
- **15 min:** Test and write notes on your approach

## Bonus Challenges

1. Add unit tests for individual components
2. Implement a transaction-like pattern so failures rollback changes
3. Make services swappable (e.g., different payment gateways)
4. Add a result object instead of boolean return values
