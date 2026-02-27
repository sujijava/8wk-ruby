# Background Jobs & Caching Strategies: Payment Processing & Comment Threads

## Overview

You'll build two important features that demonstrate understanding of concurrency and performance optimization:

1. **Idempotent Payment Processing** - Ensure payments are processed exactly once, even with retries
2. **Efficient Comment Caching** - Optimize nested comment loading with smart caching

**Time Recommendation**: Focus on Part 1 first (60-90 min), then Part 2 if time permits (60 min). Both parts are independent.

---

## Quick Start Guide

### What's Provided
- ✅ Database schema (just copy and use)
- ✅ Starter code with TODOs
- ✅ Example test structure
- ✅ Mock payment gateway that randomly succeeds/fails

### What You Need to Implement
**Part 1:**
- Fill in the TODOs in `Payment` model
- Complete `PaymentProcessor#process` method
- Handle idempotency (check if payment already exists)
- Use database locks to prevent race conditions
- Write 3-5 tests

**Part 2:**
- Load comments efficiently (no N+1 queries)
- Add `cache` blocks in the view
- Make cache invalidate when comments update
- Write 3-4 tests checking query counts

### Key Concepts You'll Use
- **Idempotency**: Same operation can be called multiple times safely
- **Database Locking**: `Payment.lock.find(id)` prevents concurrent modifications
- **N+1 Queries**: Loading items in a loop = bad. Eager loading = good.
- **Fragment Caching**: Cache HTML fragments to avoid re-rendering

---

## Part 1: Idempotent Payment Processing Job

### Context

Your platform processes payments. Sometimes the same payment processing request might be sent multiple times due to:
- User double-clicking the "Pay" button
- Network retries from the frontend
- Job system retrying failed jobs

You need to ensure that a payment is charged **exactly once**, no matter how many times the processing is triggered.

### Database Schema

```ruby
# payments table
create_table :payments do |t|
  t.integer :user_id, null: false
  t.integer :order_id, null: false
  t.decimal :amount, precision: 10, scale: 2, null: false
  t.string :status, null: false, default: 'pending'
  # status values: 'pending', 'processing', 'completed', 'failed'
  t.string :idempotency_key, null: false
  t.string :external_transaction_id
  t.text :error_message
  t.integer :retry_count, default: 0
  t.timestamps
end

add_index :payments, :idempotency_key, unique: true
add_index :payments, [:status, :created_at]
```

### Requirements

**Your goal**: Implement a `PaymentProcessor` service that safely processes payments with idempotency guarantees.

#### Core Functionality (Must Have)

1. **Idempotency Key Management**
   - Generate a unique `idempotency_key` based on `user_id` and `order_id`
   - Before processing, check if a payment with this key already exists
   - If exists and is 'completed', return the existing payment (don't process again)
   - If exists and is 'processing', wait or return (another process is handling it)

2. **Safe State Transitions**
   - Use database locks to prevent race conditions: `Payment.lock.find(id)`
   - Track the payment status: pending → processing → completed/failed
   - Never transition from 'completed' back to 'processing'

3. **Basic Retry Logic**
   - If the payment gateway fails with a transient error (timeout, 503), mark as 'failed' so it can be retried
   - Track `retry_count` and give up after 3-5 attempts
   - For permanent failures (invalid card), mark as 'failed' and don't retry

4. **External API Integration** (Simulated)
   - Create a mock `PaymentGatewayClient` that simulates API calls
   - It should randomly succeed, timeout, or fail
   - Store the `external_transaction_id` when successful

#### Key Edge Cases to Handle
- **Job executed twice simultaneously**: Use database locks (`Payment.lock`) to ensure only one process handles it
- **API succeeds but process crashes before saving**: Check the payment status again before retrying
- **API timeout**: Treat as transient failure and allow retry

#### Nice to Have (Bonus)
- Exponential backoff for retries
- Circuit breaker pattern
- Dead letter queue for permanently failed payments

#### Implementation Tasks

**Starter Code** (Fill in the TODOs):

```ruby
# app/models/payment.rb
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :order

  # Status: 'pending', 'processing', 'completed', 'failed'
  validates :status, inclusion: { in: %w[pending processing completed failed] }
  validates :idempotency_key, presence: true, uniqueness: true

  def self.generate_idempotency_key(user_id, order_id)
    "payment_#{user_id}_#{order_id}"
  end

  def can_process?
    return true if status == "pending" or status == "failed"
    return false
  end

  def processing!
    update!(status: "processing")
  end

  def complete!(external_transaction_id)
    update!(status: "completed", external_transaction_id: external_transaction_id)
  end

  def fail!(error_message)
    update!(status: "failed", retry_count: self.retry_count + 1, error_message: error_message)
  end
end

# app/services/payment_processor.rb
class PaymentProcessor
  MAX_RETRIES = 5

  def initialize(user_id:, order_id:, amount:)
    @user_id = user_id
    @order_id = order_id
    @amount = amount
  end

  def process
    # Step 1: Find or create payment with idempotency key
    payment = find_or_create_payment

    # Step 2: Check if already completed
    return payment if payment.status == 'completed'

    # Step 3: Acquire lock and check if can process
    payment = Payment.lock.find(payment.id)
    return payment unless payment.can_process?

    # Step 4: Check retry limit
    if payment.retry_count >= MAX_RETRIES
      payment.fail!("Max retries exceeded")
      return payment
    end

    payment.processing!

    # Step 6: Call payment gateway
    begin
      result = call_payment_gateway
      payment.complete!(result[:transaction_id])
    rescue PaymentGatewayError => e
      payment.fail!(e.message)
      if e.message == "Invalid card number"
        raise e
      end
    end

    payment
  end 

  private
  
  def find_or_create_payment
    idempotency_key = Payment.generate_idempotency_key(@user_id, @order_id)

    Payment.transaction do
      payment = Payment.lock.find_by(idempotency_key: idempotency_key)

      @payment = payment || Payment.create!(
        idempotency_key: idempotency_key,
        user_id: @user_id,
        order_id: @order_id,
        amount: @amount
      )
    end
  end

  def call_payment_gateway
    begin 
      PaymentGateWayClient.charge(amount: @amount, idempotency_key: @payment.idempotency_key)
    rescue PaymentGatewayError => e 
      if e.message == "Invalid card number"
        raise e
      end
    end
  end
end

# app/services/payment_gateway_client.rb
class PaymentGatewayError < StandardError; end

class PaymentGatewayClient
  def self.charge(amount:, idempotency_key:)
    # Simulate API call with random outcomes
    outcome = rand(10)

    case outcome
    when 0..6  # 70% success
      { success: true, transaction_id: "txn_#{SecureRandom.hex(8)}" }
    when 7..8  # 20% timeout (transient)
      raise PaymentGatewayError.new("Gateway timeout")
    else       # 10% invalid card (permanent)
      raise PaymentGatewayError.new("Invalid card number")
    end
  end
end

# Optional: app/jobs/process_payment_job.rb
# If you want to simulate a background job system
class ProcessPaymentJob
  def self.perform(user_id:, order_id:, amount:)
    processor = PaymentProcessor.new(
      user_id: user_id,
      order_id: order_id,
      amount: amount
    )
    processor.process
  end
end
``` 

#### Testing Requirements (Pick 4-5)

Write tests covering the most critical scenarios:

1. **Happy Path**: Payment processes successfully on first try
2. **Idempotency**: Calling `process` twice with same user_id/order_id only charges once
3. **Retry Logic**: Payment fails with timeout, then succeeds on retry
4. **Max Retries**: Payment fails 5 times and gives up
5. **Race Condition** (Advanced): Two threads try to process the same payment simultaneously
   - Hint: Use threads or multiple database connections to simulate

**Example Test Structure**:
```ruby
describe PaymentProcessor do
  it "processes payment successfully" do
    processor = PaymentProcessor.new(user_id: 1, order_id: 100, amount: 50.00)
    payment = processor.process

    expect(payment.status).to eq('completed')
    expect(payment.external_transaction_id).to be_present
  end

  it "ensures idempotency when called multiple times" do
    processor1 = PaymentProcessor.new(user_id: 1, order_id: 100, amount: 50.00)
    processor2 = PaymentProcessor.new(user_id: 1, order_id: 100, amount: 50.00)

    payment1 = processor1.process
    payment2 = processor2.process

    expect(payment1.id).to eq(payment2.id)
    expect(Payment.count).to eq(1)
    # Add check that external gateway was only called once
  end
end
```

---

## Part 2: Efficient Comment Caching

### Context

Your platform has nested comment threads (Reddit/HN style). 
When loading a post with 100 comments nested 5 levels deep, 
you're making 100+ database queries. You need to:

1. **First**: Eliminate N+1 queries when loading comments
2. **Then**: Add caching so subsequent loads don't hit the database

**Key Concept - Russian Doll Caching**: Cache fragments nest inside each other like Russian dolls. When a child comment changes, its cache key changes, which automatically invalidates its parent's cache (because the parent's cache includes the child's cache key).

### Database Schema

```ruby
# posts table
create_table :posts do |t|
  t.integer :user_id, null: false
  t.string :title, null: false
  t.text :body, null: false
  t.integer :comments_count, default: 0
  t.timestamps
end

# comments table
create_table :comments do |t|
  t.integer :post_id, null: false
  t.integer :parent_comment_id
  t.integer :user_id, null: false
  t.text :body, null: false
  t.integer :upvotes, default: 0
  t.integer :children_count, default: 0
  t.timestamps
end

add_index :comments, :post_id
add_index :comments, :parent_comment_id
add_index :comments, [:post_id, :parent_comment_id]
```

### Requirements

**Step 1: Eliminate N+1 Queries** (Must Have)
- Load all comments for a post in 1-2 queries total (use eager loading)
- Build a tree structure efficiently in memory
- No queries inside loops

**Step 2: Add Basic Caching** (Must Have)
- Cache the rendered HTML for each comment
- When a comment is updated, its cache should be invalidated
- Use Rails' built-in `cache_key_with_version` method

**Step 3: Russian Doll Caching** (Nice to Have)
- Make parent cache keys depend on child cache keys
- When a nested comment changes, parent cache automatically invalidates
- Achieve 0 database queries on cached page loads

#### Performance Targets
- **First load**: 1-2 queries (eager load all comments)
- **Cached load**: 0 queries
- **Comment update**: Invalidate only that comment (and parents if doing Russian doll caching)

#### Cache Key Strategy (For Russian Doll Implementation)

**Simple approach**: `cache_key_with_version` returns something like `comments/123-20250129103000000000`

**Russian Doll approach**: Include children's cache keys in the parent's cache key
```
post/123/v2/2025-01-29T10:30:00Z
  comment/456/v1/2025-01-29T10:25:00Z/children:789
    comment/789/v1/2025-01-29T09:15:00Z/children:none
```

When comment 789 updates (10:35):
- Its cache key changes to `comment/789/v1/2025-01-29T10:35:00Z/children:none`
- Comment 456 tries to use its cached version, but the child cache key changed
- So comment 456's cache is invalid (cache miss)
- Post 123's cache is also invalid

**The magic**: You don't manually invalidate parents. The cache key automatically includes child data, so when children change, the parent's cache lookup fails naturally.

#### Implementation Tasks

**Starter Code** (Fill in the TODOs):

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments

  def root_comments
    # TODO: Return top-level comments (where parent_comment_id is nil)
    # Hint: Load these with their children to avoid N+1
  end
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :child_comments, class_name: 'Comment', foreign_key: 'parent_comment_id'

  # Step 1: Basic approach - just use Rails' default caching
  # cache_key_with_version will include: id + updated_at

  # Step 2: Russian Doll - override to include children
  # def cache_key_with_version
  #   # TODO: Include child_comments' cache keys in this comment's cache key
  #   # Hint: "#{super}/children:#{child_comments.map(&:cache_key).join(',')}"
  # end

  def self.build_tree(comments)
    # Build a hash for quick lookups
    comments_by_id = comments.index_by(&:id)
    root_comments = []

    comments.each do |comment|
      if comment.parent_comment_id.nil?
        root_comments << comment
      else
        parent = comments_by_id[comment.parent_comment_id]
        parent.child_comments << comment if parent
      end
    end

    root_comments
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    # TODO: Load all comments efficiently (no N+1)
    # Hint: @post.comments.includes(:user) loads all comments in 1-2 queries
    # Then use Comment.build_tree to organize them

    @comments = Comment.where(post_id: @post.id)
                      .includes(:user)  # Avoid N+1 for user names
                      .order(created_at: :asc)

    @root_comments = Comment.build_tree(@comments)
  end
end

# app/views/posts/show.html.erb
<h1><%= @post.title %></h1>

<div class="comments">
  <%= render partial: 'comments/comment_tree', collection: @root_comments, as: :comment %>
</div>

# app/views/comments/_comment_tree.html.erb
<%# Simple caching (just cache each comment) %>
<% cache comment do %>
  <div class="comment" style="margin-left: <%= comment.parent_comment_id ? '20px' : '0' %>">
    <strong><%= comment.user.name %></strong>:
    <%= comment.body %>
    <em>(<%= comment.upvotes %> upvotes)</em>

    <%# Render child comments recursively %>
    <%= render partial: 'comments/comment_tree', collection: comment.child_comments, as: :comment %>
  </div>
<% end %>

<%#
  Russian Doll Caching:
  When comment.child_comments are rendered inside cache block,
  their cache keys become part of the parent's cache key automatically.
  So changing a child invalidates the parent.
%>
```

**Simpler alternative** if recursive partials are confusing:

```ruby
# Just render comments in a flat list with indentation
<% @comments.each do |comment| %>
  <% cache comment do %>
    <div style="margin-left: <%= comment.depth * 20 %>px">
      <%= comment.body %>
    </div>
  <% end %>
<% end %>
```

#### Testing Requirements (Pick 3-4)

Focus on demonstrating the key concepts:

1. **N+1 Prevention**: Show that loading a post with 20 nested comments only makes 1-2 queries
   ```ruby
   it "loads comments without N+1 queries" do
     post = create(:post)
     20.times { create(:comment, post: post) }

     expect {
       get post_path(post)
     }.to make_database_queries(count: 2) # Adjust based on your setup
   end
   ```

2. **Caching Works**: Second page load hits cache (0 queries)
   ```ruby
   it "uses cache on second load" do
     post = create(:post_with_comments)
     get post_path(post)  # First load

     expect {
       get post_path(post)  # Second load
     }.to make_database_queries(count: 0)
   end
   ```

3. **Cache Invalidation**: Updating a comment invalidates its cache
   ```ruby
   it "invalidates cache when comment is updated" do
     comment = create(:comment)
     get post_path(comment.post)  # Load and cache

     comment.update(body: "Updated text")

     expect {
       get post_path(comment.post)
     }.to make_database_queries(minimum: 1)  # Cache miss, need to reload
   end
   ```

4. **Russian Doll** (Advanced): Updating a child comment invalidates parent cache
   ```ruby
   it "invalidates parent cache when child comment updates" do
     parent = create(:comment)
     child = create(:comment, parent_comment: parent)

     # Test that parent's cache is invalidated when child changes
   end
   ```

**Tip**: Use gems like `rspec-sqlcounter` or manual query counting to verify query counts.

---

## Evaluation Criteria

### What We're Looking For

**Part 1: Payment Processing**
- ✅ Idempotency works (same payment can't be charged twice)
- ✅ Uses database locks to prevent race conditions
- ✅ Handles transient vs permanent failures differently
- ✅ Code is readable and well-organized
- ✅ Tests cover key scenarios (happy path, idempotency, retries)

**Part 2: Caching**
- ✅ Eliminates N+1 queries (loads all comments in 1-2 queries)
- ✅ Caching reduces queries to 0 on subsequent loads
- ✅ Cache invalidates when comments are updated
- ✅ Code is clear about caching strategy
- ✅ Tests verify query counts

### Not Required (Don't Over-Engineer!)
- ❌ Production-ready monitoring and alerting
- ❌ Full distributed tracing
- ❌ Circuit breaker implementation (unless you want to)
- ❌ Complex cache warming strategies
- ❌ Perfect error handling for every edge case

---

## Submission Guidelines

**Minimum Viable Submission**:
1. Working code for at least one part (Part 1 or Part 2)
2. A few tests demonstrating key functionality
3. Brief README with:
   - How to run the code
   - Key design decisions (2-3 bullet points)
   - What you would add with more time

**Good Submission**:
- Both parts implemented
- 4-5 meaningful tests per part
- Clear code with some comments on tricky parts
- README explains your approach

**Great Submission**:
- Everything above plus:
  - Bonus features (circuit breaker, Russian doll caching)
  - Thorough test coverage
  - Performance comparison (queries before/after optimization)

---

## Bonus Challenges (If You Have Extra Time)

### Payment Processing
- **Exponential Backoff**: Retry with increasing delays (1min, 5min, 15min)
- **Circuit Breaker**: Stop calling the gateway if it's consistently failing
- **Idempotent Refunds**: Support refund operations with the same guarantees
- **Better Error Classification**: Distinguish between timeout, invalid card, insufficient funds

### Caching
- **Russian Doll Caching**: Make parent caches automatically invalidate when children change
- **Redis Backend**: Use Redis instead of in-memory cache
- **Cache Metrics**: Track cache hit rates and invalidation patterns
- **Pagination**: Cache individual pages of comments

---

## Tips for Success

1. **Start Simple**: Get basic functionality working before adding complexity
2. **Test As You Go**: Write a test, make it pass, refactor, repeat
3. **Read the Database Schema**: All the fields you need are defined
4. **Use Comments**: If something is tricky, explain your reasoning
5. **Ask Questions**: In a real interview, clarifying requirements is encouraged

### Time Management
- **90 min total**: Focus on Part 1 only, get it working well
- **2-3 hours**: Do Part 1 completely, start Part 2
- **3+ hours**: Complete both parts with tests

### Common Pitfalls to Avoid
- ❌ Using `sleep` to handle race conditions (use database locks)
- ❌ Checking if payment exists, then creating it (race condition!)
- ❌ Catching all exceptions the same way (transient vs permanent)
- ❌ Loading comments in a loop (N+1 queries)
- ❌ Manually invalidating all caches (let cache keys do the work)

### Tools & Setup
- **Ruby/Rails**: Any recent version (Rails 6+ recommended for caching helpers)
- **Database**: PostgreSQL or SQLite (need transactions and locking)
- **Testing**: RSpec or Minitest (whichever you prefer)
- **Caching**: Start with `ActiveSupport::Cache::MemoryStore`

Good luck! Remember: working simple code is better than broken complex code.