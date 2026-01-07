## Month 1: Ruby & OOP Fundamentals

### Week 1: Ruby Metaprogramming & Language Internals

**Focus:** These concepts appear frequently when debugging Rails, reading gem source code, or in "extend this DSL" pairing problems.

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | Blocks, Procs, Lambdas | Build a retry mechanism: `with_retry(max: 3, delay: 2) { api_call }` that handles exceptions with exponential backoff |
| 2 | define_method, method_missing | Create a `HashProxy` class where `proxy.foo` returns `hash[:foo]` — then discuss tradeoffs of each approach |
| 3 | class_eval, instance_eval | Build a simple config DSL: `Config.define { setting :timeout, 30 }` |
| 4 | Module patterns (include, extend, prepend) | Implement a `Trackable` module that adds `created_by` and `updated_by` tracking to any class |
| 5 | Refinements | Refactor monkey-patched String methods into refinements — discuss when you'd use this in production |
| 6-7 | **Weekly Problem** | Build a mini ActiveRecord: `User.where(name: "John").order(:created_at).limit(5)` with chainable query methods |

---

### Week 2: OOP Design & SOLID

**Focus:** Live refactoring is the most common senior pairing format. Practice identifying code smells and fixing them under time pressure.

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | Single Responsibility | Refactor: Given a 200-line `OrderProcessor` class that validates, charges, sends emails, updates inventory — extract responsibilities |
| 2 | Open/Closed | Extend a payment system to add Stripe without modifying existing PayPal code |
| 3 | Dependency Injection | Refactor a class with hardcoded `HTTParty.get` calls to be testable |
| 4 | Composition vs Inheritance | Given a `Vehicle` inheritance hierarchy that's gotten messy, refactor to composition |
| 5 | Service Objects | Extract business logic from a fat controller: `OrdersController#create` that's 80 lines |
| 6-7 | **Weekly Problem** | Design a notification system: users can receive notifications via email, SMS, push, Slack. Some notifications are immediate, some batched. Make it extensible. |

---

### Week 3: Design Patterns in Ruby

**Focus:** Know 5-6 patterns cold with Ruby examples. Interviewers often ask "how would you approach X" and expect pattern vocabulary.

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | Strategy Pattern | Build a shipping cost calculator that supports multiple carriers (FedEx, UPS, USPS) with different rate algorithms |
| 2 | Decorator Pattern | Implement a `Coffee` ordering system where you can add milk, sugar, whip — price and description update dynamically |
| 3 | Factory Pattern | Create a parser factory that returns the right parser (JSON, XML, CSV) based on file extension |
| 4 | Observer Pattern | Build a stock price alerting system where multiple watchers get notified on price changes |
| 5 | Null Object Pattern | Refactor code riddled with `if user.subscription.nil?` checks |
| 6-7 | **Weekly Problem** | Build a rules engine: `PricingEngine.calculate(order)` that applies discounts, coupons, bulk pricing, loyalty points in configurable order |

---

### Week 4: Testing & Refactoring Under Pressure

**Focus:** Many pairing rounds give you failing specs and ask you to make them pass, or give you working code and ask you to add tests.

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | TDD basics | Build a `RomanNumeral` converter test-first, strictly red-green-refactor |
| 2 | Testing external APIs | Write tests for a weather service wrapper — practice stubbing, VCR-style approaches |
| 3 | Testing time-dependent code | Test a `Subscription` class with trial periods, expiration — use Timecop/travel patterns |
| 4 | Characterization tests | Given legacy code with no tests, write tests that capture current behavior before refactoring |
| 5 | Test doubles deep dive | Know when to use stub vs mock vs spy — refactor over-mocked tests |
| 6-7 | **Weekly Problem** | Given a `ReportGenerator` class with database calls, API calls, file writes — make it fully testable and write comprehensive specs in 45 minutes |

---

## Month 2: Rails, System Design & Interview Simulation

### Week 5: Rails Performance & Architecture

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | N+1 and eager loading | Given a slow endpoint, identify and fix N+1s — practice with `bullet` gem patterns |
| 2 | Database indexing | Review a schema, identify missing indexes, explain composite index ordering |
| 3 | Background jobs | Design an idempotent job for payment processing that handles retries safely |
| 4 | Caching strategies | Add Russian doll caching to a nested comment thread — handle invalidation |
| 5 | Query optimization | Rewrite a complex ActiveRecord query in raw SQL, explain when you'd do this |
| 6-7 | **Weekly Problem** | Profile and optimize an endpoint that's timing out: given a controller action that takes 8 seconds, get it under 200ms |

---

### Week 6: API Design & System Integration

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | RESTful design | Design API endpoints for a booking system — handle edge cases like conflicts, partial updates |
| 2 | Versioning strategies | Add v2 of an endpoint while maintaining v1 — discuss path vs header versioning |
| 3 | Error handling | Design a consistent error response format, implement custom exception handling |
| 4 | Rate limiting | Implement a token bucket rate limiter in Ruby |
| 5 | Webhooks | Design a webhook system: retries, signatures, idempotency keys |
| 6-7 | **Weekly Problem** | Build an API client gem: `GithubClient.new(token).repos.list(org: "rails")` with pagination, error handling, retries |

---

### Week 7: System Design for Backend Roles

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | URL shortener | Design with focus on: storage, collision handling, analytics, expiration |
| 2 | Job queue | Design Sidekiq-like system: priorities, retries, dead letter queue |
| 3 | Rate limiter (system level) | Distributed rate limiting across multiple servers |
| 4 | Feed system | Design Twitter-like feed: fan-out strategies, caching, pagination |
| 5 | Chat system | Design Slack-like: real-time delivery, persistence, read receipts |
| 6-7 | **Weekly Problem** | Full system design: E-commerce inventory system handling concurrent purchases, backorders, reservations |

---

### Week 8: Mock Interviews & Polish

| Day | Topic | Exercise |
|-----|-------|----------|
| 1 | Mock pairing #1 | 45-min refactoring problem with timer |
| 2 | Mock pairing #2 | Build a small library from scratch |
| 3 | Mock system design | 30-min system design with whiteboarding |
| 4 | Mock pairing #3 | Debug failing specs in unfamiliar codebase |
| 5 | Weak spot review | Revisit hardest problems from previous weeks |
| 6-7 | **Final Exercise** | Full interview simulation: 1 hour pairing + 30 min system design back-to-back |

---

## Daily Rhythm

- **45-60 min:** Focused exercise for the day
- **15 min:** Write notes on what you'd say out loud during pairing (practice narration)
- **15 min:** Review one Ruby/Rails blog post or conference talk

---

## Key Interview Tips

1. **Narrate your thinking** — Senior roles evaluate communication as much as coding
2. **Ask clarifying questions** — Don't assume requirements
3. **Discuss tradeoffs** — Show you understand there's no perfect solution
4. **Start simple, iterate** — Get something working first, then improve
5. **Know when to stop** — Recognize "good enough" vs over-engineering