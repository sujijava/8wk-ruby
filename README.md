## Month 1: Language Mastery + Design Thinking

### Weeks 1–2: Ruby Deep Dive (with verbal drills)

#### Exercise 1: Build a Simple ORM

**Implement:**

* `Model.find(id)`
* `Model.where(hash)`
* `model.save`

**Use:**

* `define_method`
* Class instance variables
* Basic SQL generation

**Verbal drill (5 min):**

* Why not use `method_missing`?
* Where does this abstraction leak?
* What breaks under concurrency?

---

#### Exercise 2: ActiveSupport-style `cattr_accessor`

**Requirements:**

* Implement inheritance-aware behavior
* Support overrides in subclasses

**Verbal drill:**

* Difference between class variables and class instance variables
* Why Rails avoids `@@`

---

#### Exercise 3: Retry Mechanism with Backoff

```ruby
with_retry(max: 3, backoff: :exponential) { external_api_call }
```

**Requirements:**

* Configurable backoff strategy
* Retry only specific exceptions

**Verbal drill:**

* When not to retry
* Idempotency concerns
* Observability hooks

---

### Weeks 3–4: OOP, Rails Patterns, and Boundaries

#### Exercise 4: Refactor a God Class

Start with a ~150-line `OrderProcessor`.

**Extract:**

* Validation
* Pricing
* Inventory
* Notifications

**Constraints:**

* Keep tests passing

**Verbal drill:**

* Why this is not over-engineering
* When you would stop refactoring
* Service objects vs domain models

---

#### Exercise 5: Design a Permission System

```ruby
User.can?(:edit, resource)
```

**Requirements:**

* Support growth in rules
* Prefer composition over inheritance

**Verbal drill:**

* How requirements usually expand
* Tradeoffs between policy objects vs rule tables

---

#### Exercise 6: Form Object

**Multi-model signup:**

* `User`
* `Company`
* `Subscription`

**Requirements:**

* Validations
* Error propagation

**Verbal drill:**

* Why not put this in the controller
* Transaction boundaries
* Partial failure handling

---

### Bonus (End of Month 1): Data Modeling Drill ⭐

**Design a high-volume table**
Example: `transactions`

**Cover:**

* Primary key choice (UUID vs bigint)
* Index strategy
* Soft delete vs hard delete
* When partitioning becomes necessary

**Verbal drill:**

* How this affects query performance
* Migration risks in production

---

## Month 2: Systems, Scale, and Interviews

### Weeks 5–6: Rails Performance & Reliability

#### Exercise 7: Fix N+1 + Optimize Endpoint

**Scenario:**

* Start with a ~500ms endpoint

**Techniques:**

* Eager loading
* Query reduction
* Caching

**Goal:**

* Reduce latency to < 50ms

**Verbal drill:**

* How you measured performance
* Cache invalidation strategy
* When caching hurts

---

#### Exercise 8: Idempotent Sidekiq Job

**Scenario:**

* Payment processing job

**Handle:**

* Retries
* Duplicate prevention
* Race conditions

**Verbal drill:**

* Why idempotency matters
* Database vs Redis locking
* Failure states and recovery

---

#### Exercise 9: Rate Limiter with Redis

```ruby
RateLimiter.allow?(user_id, action, limit: 100, period: 1.hour)
```

**Requirements:**

* Implement fixed window algorithm
* Discuss sliding window alternative

**Verbal drill:**

* Why Redis over DB
* TTL edge cases
* Clock drift and fairness

---

### Weeks 7–8: Interview Simulation & Storytelling

#### Exercise 10: Live Pairing Simulation

**Shopping cart discount engine**

**Discount types:**

* Percentage
* Fixed amount
* Buy-One-Get-One (BOGO)

**Requirements:**

* Priority rules
* Stacking logic
* 45-minute time box

**Must demonstrate:**

* Clear communication
* Scope control
* Willingness to simplify
