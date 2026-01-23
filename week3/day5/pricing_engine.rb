# Week 3 Day 5: Weekly Review Problem
# Build a Rules Engine: Pricing Engine
# Duration: 120-150 minutes
#
# This exercise combines multiple design patterns from this week:
# - Strategy Pattern (different pricing rules)
# - Decorator Pattern (wrapping and modifying prices)
# - Factory Pattern (creating rules dynamically)
# - Observer Pattern (tracking price changes)
# - Null Object Pattern (handling missing rules gracefully)

=begin
PROBLEM DESCRIPTION:
====================

Build a flexible pricing engine that calculates order totals by applying
pricing rules sequentially. Each rule processes the running total from the
previous rule, creating a calculation pipeline.

CRITICAL SPECIFICATIONS:
========================

1. DISCOUNT APPLICATION MODEL:
   - All discounts apply to the CURRENT RUNNING TOTAL (order-level)
   - Rules are applied sequentially in the order provided
   - Each rule receives the output total from the previous rule
   - Example: $100 → 10% off = $90 → $5 off = $85 (NOT $100 → $10 off AND $5 off = $85)

2. ITEM STRUCTURE:
   Each item has:
   - name: String
   - price: Float (price per unit, must be >= 0)
   - quantity: Integer (must be >= 1)
   - category: String (case-sensitive, e.g., "Electronics", "Books")

3. ORDER TOTAL CALCULATION:
   - Base total = sum of (item.price * item.quantity) for all items
   - Example: [{price: 100, qty: 2}, {price: 50, qty: 1}] = 100*2 + 50*1 = $250

4. RULE APPLICATION ORDER:
   Rules are applied in array order (index 0 first, then 1, then 2, etc.)
   The order MATTERS and affects final price.

RULE TYPES:
===========

1. PercentageDiscount
   - Applies X% discount to current total
   - Constructor: PercentageDiscount.new(percent: Float, min_order_amount: Float = 0)
   - Eligible: current_total >= min_order_amount
   - Formula: new_total = current_total * (1 - percent/100)
   - Example: 10% off $100 = $100 * 0.90 = $90

2. FixedDiscount
   - Subtracts fixed amount from current total
   - Constructor: FixedDiscount.new(amount: Float, min_order_amount: Float = 0)
   - Eligible: current_total >= min_order_amount
   - Formula: new_total = max(0, current_total - amount)
   - Example: $15 off $100 = $100 - $15 = $85

3. BulkPricingRule
   - Percentage discount based on TOTAL item quantity across entire order
   - Constructor: BulkPricingRule.new(min_quantity: Integer, percent: Float)
   - Eligible: sum of all item quantities >= min_quantity
   - Formula: new_total = current_total * (1 - percent/100)
   - Example: Order has 5 + 3 + 4 = 12 total items. Rule: 10+ items gets 10% off.
             $100 → $90

4. CategoryDiscount
   - Discount applied to SUBTOTAL of items in specific category only
   - Constructor: CategoryDiscount.new(category: String, percent: Float)
   - Eligible: at least one item in category exists
   - Formula:
     * category_subtotal = sum of (price * quantity) for items where item.category == category
     * discount_amount = category_subtotal * (percent/100)
     * new_total = current_total - discount_amount
   - Example: Order = [{Electronics: $500}, {Books: $100}]. 10% off Electronics.
             Current total: $600 → Electronics subtotal: $500 → Discount: $50 → New total: $550

5. CouponRule
   - Named coupon with percentage discount and minimum order requirement
   - Constructor: CouponRule.new(code: String, percent: Float, min_order_amount: Float)
   - Eligible: current_total >= min_order_amount (checked BEFORE applying discount)
   - Formula: new_total = current_total * (1 - percent/100)
   - Example: Coupon "SAVE20" = 20% off orders $100+.
             Current total: $120 → $120 * 0.80 = $96

6. LoyaltyPointsRule
   - Converts loyalty points to fixed dollar discount
   - Constructor: LoyaltyPointsRule.new(points: Integer, conversion_rate: Float)
   - Eligible: points > 0
   - Formula:
     * discount_amount = points * conversion_rate
     * new_total = max(0, current_total - discount_amount)
   - Example: 500 points at $0.01/point = $5 off. $100 → $95

RULE EXCLUSIVITY:
=================
- CouponRule: Only ONE CouponRule can be applied per order
  - If multiple coupons in rules array, apply ONLY the first eligible one
  - Subsequent coupons are skipped (marked as "skipped" in breakdown)
- All other rules can stack without limit

REQUIREMENTS:
=============

1. Core Classes:

   Order:
   - initialize() → empty order
   - add_item(name:, price:, quantity:, category:) → validates and adds item
   - remove_item(name:) → removes first item matching name
   - items → returns array of item hashes
   - base_total → Float (calculated, not stored)
   - total_quantity → Integer (sum of all item quantities)

   Item structure (use Hash):
   {
     name: String,
     price: Float,
     quantity: Integer,
     category: String
   }

   PricingEngine:
   - self.calculate(order, rules:) → PriceCalculation
   - Applies rules sequentially
   - Tracks each step for breakdown
   - Enforces coupon exclusivity

   PricingRule (abstract base class):
   - apply(current_total:, order:) → Float (new total after rule)
   - eligible?(current_total:, order:) → Boolean
   - description → String (human-readable, e.g., "Bulk discount: 10% off (5+ items)")
   - rule_type → Symbol (e.g., :percentage_discount, :coupon)

   Specific Rule Classes (inherit from PricingRule):
   - PercentageDiscount
   - FixedDiscount
   - BulkPricingRule
   - CategoryDiscount
   - CouponRule
   - LoyaltyPointsRule

   DESIGN NOTE - Rule Scope:
   All rules inherit from PricingRule and implement the same interface.
   Internally, they operate at different levels:

   Order-level (work with current_total):
   - PercentageDiscount, FixedDiscount, CouponRule, LoyaltyPointsRule
   - These rules apply calculations directly to the running total

   Item-level (iterate over order.items):
   - BulkPricingRule (examines order.total_quantity)
   - CategoryDiscount (filters items by category, calculates subtotal)
   - These rules examine items but still return a new total

   This uniform interface is intentional (Strategy Pattern) - it allows
   PricingEngine to treat all rules polymorphically without caring about
   internal implementation details. Be prepared to discuss
   this design choice and potential alternatives (see alternative_architecture.rb).

   PriceCalculation (result object):
   - original_price → Float (order base_total)
   - final_price → Float (after all eligible rules)
   - applied_rules → Array<PricingRule> (only rules that were actually applied)
   - skipped_rules → Array<PricingRule> (eligible but skipped, e.g., 2nd coupon)
   - breakdown → Array<Hash> (each step: {description:, total_before:, discount:, total_after:})

2. Design Patterns:

   Strategy Pattern:
   - Each rule class implements different discount calculation strategy
   - Rules are interchangeable via common interface (PricingRule base class)

   Observer Pattern:
   - PriceTracker class observes and logs each rule application
   - Interface: update(rule:, total_before:, total_after:)
   - PricingEngine should notify tracker for each rule

   Factory Pattern:
   - RuleFactory.create_rule(type:, **options) → PricingRule
   - type is symbol: :percentage, :fixed, :bulk, :category, :coupon, :loyalty
   - Example: RuleFactory.create_rule(type: :percentage, percent: 10, min_order_amount: 50)

   Null Object Pattern:
   - NullRule class for safe handling when no rules provided
   - eligible? always returns true
   - apply always returns current_total unchanged
   - description returns "No discount applied"

3. Validation & Edge Cases:

   Input Validation:
   - Order.add_item: price >= 0, quantity >= 1, name and category non-empty
   - All discount percentages: 0 <= percent <= 100
   - All amounts: >= 0
   - Raise ArgumentError for invalid inputs

   Edge Cases to Handle:
   - Empty order (base_total = 0): all rules skipped, final_price = 0
   - Rules resulting in negative total: floor at 0.0
   - No eligible rules: final_price = original_price
   - Empty rules array: use NullRule
   - Multiple coupons: apply first eligible only
   - Category not in order: CategoryDiscount skipped

PRECISE EXAMPLE:
================

# Create order
order = Order.new
order.add_item(name: "Laptop", price: 1000.0, quantity: 1, category: "Electronics")
order.add_item(name: "Mouse", price: 25.0, quantity: 2, category: "Electronics")
order.add_item(name: "Book", price: 15.0, quantity: 3, category: "Books")

# Order state:
# Items: [
#   {name: "Laptop", price: 1000.0, quantity: 1, category: "Electronics"},
#   {name: "Mouse", price: 25.0, quantity: 2, category: "Electronics"},
#   {name: "Book", price: 15.0, quantity: 3, category: "Books"}
# ]
# base_total = 1000*1 + 25*2 + 15*3 = 1000 + 50 + 45 = 1095.0
# total_quantity = 1 + 2 + 3 = 6 items

# Define rules (will be applied in THIS order)
rules = [
  BulkPricingRule.new(min_quantity: 5, percent: 10),
  CategoryDiscount.new(category: "Electronics", percent: 5),
  CouponRule.new(code: "SAVE20", percent: 20, min_order_amount: 100.0),
  LoyaltyPointsRule.new(points: 500, conversion_rate: 0.01)
]

# Calculate
calculation = PricingEngine.calculate(order, rules: rules)

# Expected results:
calculation.original_price  # => 1095.0

# Step-by-step:
# 1. BulkPricingRule: 6 items >= 5 ✓ eligible
#    1095.0 * (1 - 10/100) = 1095.0 * 0.90 = 985.50

# 2. CategoryDiscount (Electronics): Electronics subtotal = 1000 + 50 = 1050
#    Discount = 1050 * 0.05 = 52.50
#    985.50 - 52.50 = 933.00

# 3. CouponRule: current_total 933.00 >= 100.0 ✓ eligible
#    933.00 * (1 - 20/100) = 933.00 * 0.80 = 746.40

# 4. LoyaltyPointsRule: discount = 500 * 0.01 = 5.00
#    746.40 - 5.00 = 741.40

calculation.final_price  # => 741.40

calculation.breakdown
# => [
#   {
#     description: "Bulk discount: 10% off (5+ items)",
#     total_before: 1095.0,
#     discount: 109.50,
#     total_after: 985.50
#   },
#   {
#     description: "Category discount: 5% off Electronics",
#     total_before: 985.50,
#     discount: 52.50,
#     total_after: 933.00
#   },
#   {
#     description: "Coupon SAVE20: 20% off orders $100+",
#     total_before: 933.00,
#     discount: 186.60,
#     total_after: 746.40
#   },
#   {
#     description: "Loyalty points: $5.00 off (500 points)",
#     total_before: 746.40,
#     discount: 5.00,
#     total_after: 741.40
#   }
# ]

calculation.applied_rules.length  # => 4
calculation.skipped_rules.length  # => 0

ADDITIONAL TEST CASES:
======================

Test Case 1: Multiple Coupons (only first applied)
---------------------------------------------------
order = Order.new
order.add_item(name: "Item", price: 200.0, quantity: 1, category: "General")

rules = [
  CouponRule.new(code: "FIRST", percent: 10, min_order_amount: 100.0),
  CouponRule.new(code: "SECOND", percent: 20, min_order_amount: 100.0)
]

calculation = PricingEngine.calculate(order, rules: rules)
# original_price: 200.0
# After FIRST coupon: 200.0 * 0.90 = 180.0
# SECOND coupon: SKIPPED (coupon already applied)
# final_price: 180.0
# applied_rules.length: 1 (only FIRST)
# skipped_rules.length: 1 (SECOND)


Test Case 2: Rule Order Matters
--------------------------------
order = Order.new
order.add_item(name: "Item", price: 100.0, quantity: 1, category: "General")

# Scenario A: Percentage then Fixed
rules_a = [
  PercentageDiscount.new(percent: 10),
  FixedDiscount.new(amount: 5)
]
# 100 → 90 → 85 = $85

# Scenario B: Fixed then Percentage
rules_b = [
  FixedDiscount.new(amount: 5),
  PercentageDiscount.new(percent: 10)
]
# 100 → 95 → 85.50 = $85.50

# Different final prices!


Test Case 3: Discount Exceeds Total (floor at 0)
-------------------------------------------------
order = Order.new
order.add_item(name: "Item", price: 10.0, quantity: 1, category: "General")

rules = [
  FixedDiscount.new(amount: 50.0)
]

calculation = PricingEngine.calculate(order, rules: rules)
# original_price: 10.0
# After FixedDiscount: max(0, 10 - 50) = 0.0
# final_price: 0.0


Test Case 4: No Eligible Rules
-------------------------------
order = Order.new
order.add_item(name: "Item", price: 50.0, quantity: 1, category: "General")

rules = [
  PercentageDiscount.new(percent: 10, min_order_amount: 100.0),  # Not eligible
  BulkPricingRule.new(min_quantity: 10, percent: 20)              # Not eligible
]

calculation = PricingEngine.calculate(order, rules: rules)
# original_price: 50.0
# final_price: 50.0 (no changes)
# applied_rules.length: 0
# skipped_rules.length: 2


Test Case 5: Empty Order
-------------------------
order = Order.new

rules = [
  PercentageDiscount.new(percent: 10),
  FixedDiscount.new(amount: 5)
]

calculation = PricingEngine.calculate(order, rules: rules)
# original_price: 0.0
# final_price: 0.0
# applied_rules.length: 0 (all skipped)


Test Case 6: Category Not in Order
-----------------------------------
order = Order.new
order.add_item(name: "Book", price: 20.0, quantity: 1, category: "Books")

rules = [
  CategoryDiscount.new(category: "Electronics", percent: 10)
]

calculation = PricingEngine.calculate(order, rules: rules)
# original_price: 20.0
# final_price: 20.0
# applied_rules.length: 0
# skipped_rules.length: 1


BONUS CHALLENGES:
=================

1. Priority System
   - Add priority: Integer field to PricingRule
   - Auto-sort rules by priority before applying (higher priority first)
   - Equal priority: maintain original order

2. Buy X Get Y Free
   - QuantityPromotion.new(buy_quantity: Integer, free_quantity: Integer, category: String)
   - Example: Buy 2 get 1 free in "Books"
   - Calculate discount as price of cheapest free items

3. Time-Based Rules
   - Add valid_from: Time, valid_until: Time to rules
   - Check Time.now within range in eligible?
   - Example: Happy hour 3-6pm daily

4. Conflict Detection
   - RuleConflictDetector.check(rules) → Array<String> (warnings)
   - Detect: multiple coupons, contradictory rules, redundant rules
   - Return human-readable warnings

5. DSL for Rules
   PricingEngine.configure do
     rule :bulk, min_quantity: 10, percent: 15
     rule :coupon, code: "WELCOME", percent: 10, min_order_amount: 50
     rule :category, name: "Electronics", percent: 5
   end

6. Rule Composition
   - CompositeRule.new(rules: [...], strategy: :all | :any | :best)
   - :all = apply all sub-rules sequentially
   - :any = apply first eligible sub-rule
   - :best = apply sub-rule giving best discount

7. A/B Testing
   - PricingEngine.calculate_variants(order, rule_sets: {control: [...], variant_a: [...]})
   - Returns hash of PriceCalculation for each variant
   - Track conversion metrics

DELIVERABLES:
=============

1. ✓ All core classes implemented with proper inheritance
2. ✓ All 6 rule types working correctly
3. ✓ Factory pattern for rule creation
4. ✓ Observer pattern with PriceTracker
5. ✓ Null object pattern for missing/empty rules
6. ✓ Test cases: minimum 5 scenarios from test cases above
7. ✓ Input validation with ArgumentError for invalid data
8. ✓ Code comments explaining design decisions
9. ✓ Brief write-up (10-15 lines) on pattern usage and trade-offs

EVALUATION CRITERIA:
====================

1. Correctness (40%):
   - All test cases pass with exact expected values
   - Edge cases handled properly
   - Math is precise (use Float, round to 2 decimals for display only)

2. Design Patterns (25%):
   - Proper implementation of Strategy, Observer, Factory, Null Object
   - Patterns used appropriately (not forced)
   - Clear separation of concerns

3. Code Quality (20%):
   - DRY (Don't Repeat Yourself)
   - Single Responsibility Principle
   - Readable variable/method names
   - Consistent style

4. Extensibility (15%):
   - Easy to add new rule types
   - Easy to modify rule behavior
   - Minimal changes needed for new features

TIPS FOR SUCCESS:
=================

1. Start with Order and Item - get base_total working first
2. Implement PricingRule base class with clear interface
3. Implement one rule type at a time, test thoroughly
4. Build PricingEngine to apply rules sequentially
5. Add PriceCalculation to capture results
6. Implement Factory, Observer, Null Object last
7. Test each rule type in isolation before combining
8. Use precise Float arithmetic - don't round until display
9. Read the PRECISE EXAMPLE section multiple times
10. Verify your math manually before running code

COMMON PITFALLS TO AVOID:
=========================

- ✗ Applying all discounts to original price (should be sequential)
- ✗ Rounding intermediate values (round only final display)
- ✗ Allowing multiple coupons (only first eligible)
- ✗ Forgetting to check eligibility before applying
- ✗ Not handling negative totals (floor at 0)
- ✗ Hardcoding rule types (should be extensible)
- ✗ Mixing calculation and presentation logic
- ✗ Not validating inputs
- ✗ Unclear method/variable names
- ✗ God classes doing too much

Good luck! This problem tests your ability to:
- Design clean, extensible systems
- Apply design patterns appropriately
- Handle complex business logic
- Write production-quality code
- Think through edge cases
=end

# TODO: Implement your solution below

# Suggested implementation order:
# 1. Order class with add_item, base_total, total_quantity
# 2. PricingRule base class
# 3. One simple rule (e.g., PercentageDiscount)
# 4. PricingEngine.calculate with sequential application
# 5. PriceCalculation result object
# 6. Remaining rule types
# 7. Coupon exclusivity logic
# 8. Factory, Observer, Null Object patterns
# 9. Validation and edge cases
# 10. Test scenarios
