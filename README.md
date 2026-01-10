## Month 1: Ruby & OOP Fundamentals

### Week 1: Ruby Metaprogramming & Language Internals

**Focus:** These concepts appear frequently when debugging Rails, reading gem source code, or in "extend this DSL" pairing problems.

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | Blocks, Procs, Lambdas | Build a retry mechanism: `with_retry(max: 3, delay: 2) { api_call }` that handles exceptions with exponential backoff |
| Tue | define_method, method_missing | Create a `HashProxy` class where `proxy.foo` returns `hash[:foo]` — then discuss tradeoffs of each approach |
| Wed | class_eval, instance_eval + Module patterns | Build a simple config DSL: `Config.define { setting :timeout, 30 }`, then implement a `Trackable` module that adds `created_by` and `updated_by` tracking to any class |
| Thu | Refinements + Metaprogramming Deep Dive | Refactor monkey-patched String methods into refinements, then build a custom DSL using multiple metaprogramming techniques |
| Fri | **Weekly Review Problem** | Build a mini ActiveRecord: `User.where(name: "John").order(:created_at).limit(5)` with chainable query methods |

---

### Week 2: OOP Design & SOLID

**Focus:** Live refactoring is the most common senior pairing format. Practice identifying code smells and fixing them under time pressure.

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | Single Responsibility Principle | Refactor: Given a 200-line `OrderProcessor` class that validates, charges, sends emails, updates inventory — extract responsibilities |
| Tue | Open/Closed Principle | Extend a payment system to add Stripe without modifying existing PayPal code |
| Wed | Dependency Injection + Service Objects | Refactor a class with hardcoded `HTTParty.get` calls to be testable, then extract business logic from a fat controller: `OrdersController#create` that's 80 lines |
| Thu | Composition vs Inheritance + SOLID Review | Given a `Vehicle` inheritance hierarchy that's gotten messy, refactor to composition. Apply multiple SOLID principles to a complex codebase |
| Fri | **Weekly Review Problem** | Design a notification system: users can receive notifications via email, SMS, push, Slack. Some notifications are immediate, some batched. Make it extensible. |

---

### Week 3: Design Patterns in Ruby

**Focus:** Know 5-6 patterns cold with Ruby examples. Interviewers often ask "how would you approach X" and expect pattern vocabulary.

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | Strategy Pattern | Build a shipping cost calculator that supports multiple carriers (FedEx, UPS, USPS) with different rate algorithms |
| Tue | Decorator Pattern | Implement a `Coffee` ordering system where you can add milk, sugar, whip — price and description update dynamically |
| Wed | Factory + Observer Patterns | Create a parser factory that returns the right parser (JSON, XML, CSV) based on file extension, then build a stock price alerting system where multiple watchers get notified on price changes |
| Thu | Null Object + Pattern Combinations | Refactor code riddled with `if user.subscription.nil?` checks, then solve complex problems by combining multiple patterns |
| Fri | **Weekly Review Problem** | Build a rules engine: `PricingEngine.calculate(order)` that applies discounts, coupons, bulk pricing, loyalty points in configurable order |

---

### Week 4: Testing & Refactoring Under Pressure

**Focus:** Many pairing rounds give you failing specs and ask you to make them pass, or give you working code and ask you to add tests.

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | TDD Basics | Build a `RomanNumeral` converter test-first, strictly red-green-refactor |
| Tue | Testing External APIs | Write tests for a weather service wrapper — practice stubbing, VCR-style approaches |
| Wed | Testing Time-Dependent Code + Characterization Tests | Test a `Subscription` class with trial periods, expiration — use Timecop/travel patterns. Then, given legacy code with no tests, write tests that capture current behavior before refactoring |
| Thu | Test Doubles Deep Dive + Advanced Testing Patterns | Know when to use stub vs mock vs spy — refactor over-mocked tests. Practice testing complex scenarios with multiple dependencies |
| Fri | **Weekly Review Problem** | Given a `ReportGenerator` class with database calls, API calls, file writes — make it fully testable and write comprehensive specs in 45 minutes |

---

## Month 2: Rails, System Design & Interview Simulation

### Week 5: Rails Performance & Architecture

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | N+1 and Eager Loading | Given a slow endpoint, identify and fix N+1s — practice with `bullet` gem patterns |
| Tue | Database Indexing | Review a schema, identify missing indexes, explain composite index ordering |
| Wed | Background Jobs + Caching Strategies | Design an idempotent job for payment processing that handles retries safely. Then add Russian doll caching to a nested comment thread — handle invalidation |
| Thu | Query Optimization + Performance Deep Dive | Rewrite a complex ActiveRecord query in raw SQL, explain when you'd do this. Practice profiling and identifying bottlenecks in a Rails app |
| Fri | **Weekly Review Problem** | Profile and optimize an endpoint that's timing out: given a controller action that takes 8 seconds, get it under 200ms |

---

### Week 6: API Design & System Integration

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | RESTful Design | Design API endpoints for a booking system — handle edge cases like conflicts, partial updates |
| Tue | Versioning + Error Handling | Add v2 of an endpoint while maintaining v1 — discuss path vs header versioning. Design a consistent error response format, implement custom exception handling |
| Wed | Rate Limiting + Webhooks | Implement a token bucket rate limiter in Ruby. Then design a webhook system: retries, signatures, idempotency keys |
| Thu | API Client Design + Advanced Integration Patterns | Build a fluent API client interface with chainable methods. Practice handling complex API scenarios: pagination, cursor-based pagination, retries with backoff |
| Fri | **Weekly Review Problem** | Build an API client gem: `GithubClient.new(token).repos.list(org: "rails")` with pagination, error handling, retries |

---

### Week 7: System Design for Backend Roles

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | URL Shortener | Design with focus on: storage, collision handling, analytics, expiration |
| Tue | Job Queue System | Design Sidekiq-like system: priorities, retries, dead letter queue |
| Wed | Rate Limiter (System Level) + Feed System | Distributed rate limiting across multiple servers. Then design Twitter-like feed: fan-out strategies, caching, pagination |
| Thu | Chat System + Real-Time Architecture | Design Slack-like: real-time delivery, persistence, read receipts. Discuss WebSocket architecture, message queues, consistency patterns |
| Fri | **Weekly Review Problem** | Full system design: E-commerce inventory system handling concurrent purchases, backorders, reservations |

---

### Week 8: Mock Interviews & Polish

| Day | Topic | Exercise |
|-----|-------|----------|
| Mon | Mock Pairing #1 | 45-min refactoring problem with timer |
| Tue | Mock Pairing #2 | Build a small library from scratch |
| Wed | Mock System Design + Mock Pairing #3 | 30-min system design with whiteboarding. Then debug failing specs in unfamiliar codebase |
| Thu | Weak Spot Review + Advanced Mock Interview | Revisit hardest problems from previous weeks. Practice articulating tradeoffs and design decisions under pressure |
| Fri | **Final Exercise** | Full interview simulation: 1 hour pairing + 30 min system design back-to-back |

---

## Daily Rhythm

**Monday/Tuesday (Lighter Days):**
- **45-60 min:** Focused exercise for the day
- **15 min:** Write notes on what you'd say out loud during pairing (practice narration)
- **15 min:** Review one Ruby/Rails blog post or conference talk

**Wednesday/Thursday (Deeper Dive Days):**
- **90-120 min:** Work through multiple exercises or dig deeper into complex topics
- **20 min:** Document your approach and tradeoffs for each problem
- **15 min:** Review related advanced articles or gem source code

**Friday (Weekly Review Day):**
- **120-150 min:** Tackle the weekly problem end-to-end
- **30 min:** Write a full retrospective: what patterns did you use, what would you do differently, what did you learn from the week
- **15 min:** Plan focus areas for the following week

---

## Key Interview Tips

1. **Narrate your thinking** — Senior roles evaluate communication as much as coding
2. **Ask clarifying questions** — Don't assume requirements
3. **Discuss tradeoffs** — Show you understand there's no perfect solution
4. **Start simple, iterate** — Get something working first, then improve
5. **Know when to stop** — Recognize "good enough" vs over-engineering