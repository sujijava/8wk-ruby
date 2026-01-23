# Week 3 Day 5 - Pricing Engine Takeaways

## 1. Order needs TWO totals for sequential rule application
- `base_total` - Original price (never changes, for display to user)
- `discounted_total` - Running total after each rule (gets updated as rules apply)

**Why:** Rules must chain their calculations. Each rule operates on the result of the previous rule, not the original total.

Example:
- Start: $100
- After 10% off: $90 (operate on $100)
- After $5 off: $85 (operate on $90, NOT $100)

## 2. Always use Float for monetary calculations
```ruby
price = 100.0  # ✓ Float
discount = 10.0 / 100.0  # ✓ Float division ensures precision

# Not:
price = 100  # ✗ Integer causes rounding errors
discount = 10 / 100  # ✗ Integer division = 0
```

**Why:** Prevents precision loss in discount calculations. Only round to 2 decimals for display, never in intermediate calculations.
