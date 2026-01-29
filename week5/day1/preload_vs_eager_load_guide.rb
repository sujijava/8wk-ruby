# ============================================================================
# PRELOAD vs EAGER_LOAD vs INCLUDES - COMPREHENSIVE GUIDE
# ============================================================================
#
# Understanding these three methods is CRITICAL for Rails performance.
# They all solve N+1 queries, but in different ways.
#
# ============================================================================

# ============================================================================
# 1. PRELOAD - Always 2+ Separate Queries
# ============================================================================

puts "=" * 80
puts "1. PRELOAD - Separate Queries Strategy"
puts "=" * 80

# Example 1: Basic Preload
puts "\nPost.preload(:author).limit(5)"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT * FROM posts LIMIT 5"
puts "  Query 2: SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5)"
puts ""
puts "Result: 2 queries total, loads posts then loads all related authors"

# Example 2: Preload with Multiple Associations
puts "\nPost.preload(:author, :comments).limit(5)"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT * FROM posts LIMIT 5"
puts "  Query 2: SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5)"
puts "  Query 3: SELECT * FROM comments WHERE post_id IN (1, 2, 3, 4, 5)"
puts ""
puts "Result: 3 queries total (1 + N associations)"

# Example 3: Preload with Nested Associations
puts "\nPost.preload(comments: :user).limit(5)"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT * FROM posts LIMIT 5"
puts "  Query 2: SELECT * FROM comments WHERE post_id IN (1, 2, 3, 4, 5)"
puts "  Query 3: SELECT * FROM users WHERE id IN (10, 11, 12, ...)"
puts ""
puts "Result: 3 queries total, each level loads separately"

# ============================================================================
# 2. EAGER_LOAD - Always 1 Query with LEFT OUTER JOIN
# ============================================================================

puts "\n" + "=" * 80
puts "2. EAGER_LOAD - LEFT OUTER JOIN Strategy"
puts "=" * 80

# Example 1: Basic Eager Load
puts "\nPost.eager_load(:author).limit(5)"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT posts.*, users.*"
puts "           FROM posts"
puts "           LEFT OUTER JOIN users ON users.id = posts.author_id"
puts "           LIMIT 5"
puts ""
puts "Result: 1 query total, loads posts and authors together"

# Example 2: Eager Load with Multiple Associations
puts "\nPost.eager_load(:author, :comments).limit(5)"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT posts.*, users.*, comments.*"
puts "           FROM posts"
puts "           LEFT OUTER JOIN users ON users.id = posts.author_id"
puts "           LEFT OUTER JOIN comments ON comments.post_id = posts.id"
puts "           LIMIT 5"
puts ""
puts "Result: 1 huge query with multiple JOINs"

# Example 3: Eager Load with WHERE on Association
puts "\nPost.eager_load(:author).where(users: { verified: true })"
puts "-" * 40
puts "SQL Generated:"
puts "  Query 1: SELECT posts.*, users.*"
puts "           FROM posts"
puts "           LEFT OUTER JOIN users ON users.id = posts.author_id"
puts "           WHERE users.verified = true"
puts ""
puts "Result: 1 query, can filter on joined table!"

# ============================================================================
# 3. INCLUDES - Smart Choice (Preload OR Eager Load)
# ============================================================================

puts "\n" + "=" * 80
puts "3. INCLUDES - Smart Strategy (Chooses for You)"
puts "=" * 80

# Example 1: Includes without WHERE on association → Uses PRELOAD
puts "\nPost.includes(:author).limit(5)"
puts "-" * 40
puts "ActiveRecord Chooses: PRELOAD"
puts "SQL Generated:"
puts "  Query 1: SELECT * FROM posts LIMIT 5"
puts "  Query 2: SELECT * FROM users WHERE id IN (1, 2, 3, 4, 5)"
puts ""
puts "Why? No need to JOIN, separate queries are cleaner"

# Example 2: Includes WITH WHERE on association → Uses EAGER_LOAD
puts "\nPost.includes(:author).where(users: { verified: true })"
puts "-" * 40
puts "ActiveRecord Chooses: EAGER_LOAD"
puts "SQL Generated:"
puts "  Query 1: SELECT posts.*, users.*"
puts "           FROM posts"
puts "           LEFT OUTER JOIN users ON users.id = posts.author_id"
puts "           WHERE users.verified = true"
puts ""
puts "Why? Must JOIN to filter on users table"

# Example 3: Includes with ORDER BY on association → Uses EAGER_LOAD
puts "\nPost.includes(:author).order('users.name ASC')"
puts "-" * 40
puts "ActiveRecord Chooses: EAGER_LOAD"
puts "SQL Generated:"
puts "  Query 1: SELECT posts.*, users.*"
puts "           FROM posts"
puts "           LEFT OUTER JOIN users ON users.id = posts.author_id"
puts "           ORDER BY users.name ASC"
puts ""
puts "Why? Must JOIN to order by users.name"

# ============================================================================
# 4. VISUAL COMPARISON
# ============================================================================

puts "\n" + "=" * 80
puts "4. VISUAL COMPARISON"
puts "=" * 80

puts "\n┌─────────────────┬──────────────────┬──────────────────┬────────────────┐"
puts "│ Method          │ # Queries        │ Uses JOIN?       │ When to Use    │"
puts "├─────────────────┼──────────────────┼──────────────────┼────────────────┤"
puts "│ .preload()      │ Always 2+        │ Never            │ Simple loading │"
puts "│ .eager_load()   │ Always 1         │ Always (JOIN)    │ Filtering/Sort │"
puts "│ .includes()     │ Smart (2+ or 1)  │ When needed      │ Default choice │"
puts "└─────────────────┴──────────────────┴──────────────────┴────────────────┘"

# ============================================================================
# 5. WHEN TO USE EACH
# ============================================================================

puts "\n" + "=" * 80
puts "5. WHEN TO USE EACH"
puts "=" * 80

puts "\n✅ USE .preload() WHEN:"
puts "   • Simple eager loading (no filtering on associations)"
puts "   • You want separate, simple queries"
puts "   • You have has_many relationships (avoid cartesian product)"
puts "   • Memory is not a concern"
puts ""
puts "   Example: Post.preload(:comments)"
puts "   → Better for has_many (avoids duplicate post data)"

puts "\n✅ USE .eager_load() WHEN:"
puts "   • Filtering on associated table (.where on association)"
puts "   • Sorting by associated column (.order on association)"
puts "   • You want a single query"
puts "   • You need to reference associations in SQL"
puts ""
puts "   Example: Post.eager_load(:author).where(users: { verified: true })"
puts "   → Required to filter by author attributes"

puts "\n✅ USE .includes() WHEN:"
puts "   • You're not sure which to use (default choice)"
puts "   • Let ActiveRecord decide the optimal strategy"
puts "   • You might add filtering later"
puts "   • General eager loading needs"
puts ""
puts "   Example: Post.includes(:author, :comments)"
puts "   → Rails picks the best approach automatically"

# ============================================================================
# 6. GOTCHAS & COMMON MISTAKES
# ============================================================================

puts "\n" + "=" * 80
puts "6. GOTCHAS & COMMON MISTAKES"
puts "=" * 80

puts "\n⚠️  GOTCHA #1: Cartesian Product with eager_load"
puts "-" * 40
puts "Post.eager_load(:comments).limit(5)"
puts ""
puts "Problem: If each post has 10 comments, you get 50 rows back!"
puts "  Post 1 × 10 comments = 10 rows"
puts "  Post 2 × 10 comments = 10 rows"
puts "  ... = 50 rows total"
puts ""
puts "ActiveRecord deduplicates in Ruby, but it's inefficient."
puts ""
puts "✅ Better: Use .preload() for has_many"
puts "   Post.preload(:comments).limit(5)"
puts "   → 2 queries, no duplication: SELECT posts, then SELECT comments"

puts "\n⚠️  GOTCHA #2: Can't use .where on preload"
puts "-" * 40
puts "# ❌ This fails:"
puts "Post.preload(:author).where(users: { verified: true })"
puts "# Error: Can't reference 'users' table (not joined)"
puts ""
puts "✅ Solution: Use .eager_load or .includes"
puts "   Post.eager_load(:author).where(users: { verified: true })"
puts "   Post.includes(:author).where(users: { verified: true })"

puts "\n⚠️  GOTCHA #3: Memory usage with eager_load"
puts "-" * 40
puts "Post.eager_load(:comments, :tags, :likes).limit(1000)"
puts ""
puts "Problem: Cartesian product = 1000 posts × 10 comments × 5 tags × 20 likes"
puts "  = 1,000,000 rows loaded into memory!"
puts ""
puts "✅ Better: Use .preload() for multiple has_many"
puts "   Post.preload(:comments, :tags, :likes).limit(1000)"
puts "   → 4 queries: posts, comments, tags, likes (separate, efficient)"

puts "\n⚠️  GOTCHA #4: Counter cache vs eager loading counts"
puts "-" * 40
puts "# ❌ N+1 even with includes:"
puts "Post.includes(:comments).each { |p| puts p.comments.count }"
puts "# Problem: .count triggers COUNT(*) query per post!"
puts ""
puts "✅ Solution 1: Use .size (uses cached array)"
puts "   Post.includes(:comments).each { |p| puts p.comments.size }"
puts ""
puts "✅ Solution 2: Add counter_cache (best for production)"
puts "   class Comment"
puts "     belongs_to :post, counter_cache: true"
puts "   end"
puts "   # Now post.comments_count is instant (no query)"

# ============================================================================
# 7. PERFORMANCE COMPARISON
# ============================================================================

puts "\n" + "=" * 80
puts "7. PERFORMANCE COMPARISON"
puts "=" * 80

puts "\nScenario: Load 100 posts with authors"
puts "-" * 40

puts "\n❌ No Eager Loading (N+1):"
puts "   Post.all.each { |p| p.author.name }"
puts "   Queries: 101 (1 for posts + 100 for authors)"
puts "   Time: ~5 seconds"

puts "\n✅ With .preload():"
puts "   Post.preload(:author).each { |p| p.author.name }"
puts "   Queries: 2 (1 for posts, 1 for authors)"
puts "   Time: ~50ms"
puts "   SQL:"
puts "     1. SELECT * FROM posts"
puts "     2. SELECT * FROM users WHERE id IN (1,2,3,...,100)"

puts "\n✅ With .eager_load():"
puts "   Post.eager_load(:author).each { |p| p.author.name }"
puts "   Queries: 1 (JOIN query)"
puts "   Time: ~60ms (slightly slower due to JOIN overhead)"
puts "   SQL:"
puts "     1. SELECT posts.*, users.* FROM posts"
puts "        LEFT OUTER JOIN users ON users.id = posts.author_id"

puts "\n✅ With .includes():"
puts "   Post.includes(:author).each { |p| p.author.name }"
puts "   Queries: 2 (chooses preload)"
puts "   Time: ~50ms"
puts "   (Rails picks preload since no WHERE/ORDER on users)"

# ============================================================================
# 8. REAL-WORLD EXAMPLES
# ============================================================================

puts "\n" + "=" * 80
puts "8. REAL-WORLD EXAMPLES"
puts "=" * 80

puts "\n📌 Example 1: Blog Dashboard"
puts "-" * 40
puts "# Load posts with authors and comment counts"
puts ""
puts "# ❌ Bad (N+1):"
puts "@posts = Post.all"
puts "@posts.each do |post|"
puts "  puts post.author.name        # N+1"
puts "  puts post.comments.count     # N+1"
puts "end"
puts ""
puts "# ✅ Good:"
puts "@posts = Post.includes(:author, :comments)"
puts "@posts.each do |post|"
puts "  puts post.author.name        # cached"
puts "  puts post.comments.size      # cached array"
puts "end"

puts "\n📌 Example 2: Filter by Association"
puts "-" * 40
puts "# Show posts by verified authors only"
puts ""
puts "# ❌ Won't work:"
puts "Post.preload(:author).where(users: { verified: true })"
puts "# Error: users table not in query"
puts ""
puts "# ✅ Correct:"
puts "Post.eager_load(:author).where(users: { verified: true })"
puts "# Or:"
puts "Post.includes(:author).where(users: { verified: true })"
puts "# (includes automatically switches to eager_load)"

puts "\n📌 Example 3: Complex Dashboard"
puts "-" * 40
puts "# Load users with their posts, comments, and company"
puts ""
puts "# ✅ Best approach:"
puts "User.includes(:company, posts: :comments)"
puts ""
puts "Queries:"
puts "  1. SELECT * FROM users"
puts "  2. SELECT * FROM companies WHERE id IN (...)"
puts "  3. SELECT * FROM posts WHERE user_id IN (...)"
puts "  4. SELECT * FROM comments WHERE post_id IN (...)"
puts ""
puts "Result: 4 clean queries instead of hundreds"

# ============================================================================
# 9. DECISION FLOWCHART
# ============================================================================

puts "\n" + "=" * 80
puts "9. DECISION FLOWCHART"
puts "=" * 80

puts "\n"
puts "  Do you need to eager load?"
puts "          │"
puts "          ├─ No ──→ Don't use any (lazy load)"
puts "          │"
puts "          └─ Yes"
puts "              │"
puts "              ├─ Filtering on association? (.where on associated table)"
puts "              │   │"
puts "              │   └─ Yes ──→ Use .eager_load() or .includes()"
puts "              │"
puts "              ├─ Sorting by association? (.order on associated column)"
puts "              │   │"
puts "              │   └─ Yes ──→ Use .eager_load() or .includes()"
puts "              │"
puts "              ├─ Multiple has_many associations?"
puts "              │   │"
puts "              │   └─ Yes ──→ Use .preload() (avoids cartesian product)"
puts "              │"
puts "              └─ Simple eager loading?"
puts "                  │"
puts "                  └─ Yes ──→ Use .includes() (let Rails decide)"

# ============================================================================
# 10. QUICK REFERENCE
# ============================================================================

puts "\n" + "=" * 80
puts "10. QUICK REFERENCE CHEAT SHEET"
puts "=" * 80

puts "\n┌────────────────────────────────────────────────────────────────┐"
puts "│ PRELOAD                                                        │"
puts "├────────────────────────────────────────────────────────────────┤"
puts "│ Strategy:  Separate queries                                   │"
puts "│ Queries:   2+ (1 per association)                             │"
puts "│ When:      Simple loading, has_many associations              │"
puts "│ Pros:      No cartesian product, simple SQL                   │"
puts "│ Cons:      Multiple queries, can't filter on associations     │"
puts "│ Example:   Post.preload(:comments)                            │"
puts "└────────────────────────────────────────────────────────────────┘"

puts "\n┌────────────────────────────────────────────────────────────────┐"
puts "│ EAGER_LOAD                                                     │"
puts "├────────────────────────────────────────────────────────────────┤"
puts "│ Strategy:  LEFT OUTER JOIN                                    │"
puts "│ Queries:   1 (all data in one query)                          │"
puts "│ When:      Filtering/sorting on associations                  │"
puts "│ Pros:      Single query, can use WHERE/ORDER on associations  │"
puts "│ Cons:      Cartesian product with has_many, complex SQL       │"
puts "│ Example:   Post.eager_load(:author).where(users: {verified:t})│"
puts "└────────────────────────────────────────────────────────────────┘"

puts "\n┌────────────────────────────────────────────────────────────────┐"
puts "│ INCLUDES (Recommended)                                         │"
puts "├────────────────────────────────────────────────────────────────┤"
puts "│ Strategy:  Smart (picks preload or eager_load)                │"
puts "│ Queries:   Depends (2+ or 1)                                  │"
puts "│ When:      Default choice for eager loading                   │"
puts "│ Pros:      Rails optimizes, works in all cases                │"
puts "│ Cons:      Less control over strategy                         │"
puts "│ Example:   Post.includes(:author, :comments)                  │"
puts "└────────────────────────────────────────────────────────────────┘"

puts "\n" + "=" * 80
puts "💡 TL;DR: Use .includes() unless you have a specific reason not to!"
puts "=" * 80

# ============================================================================
# 11. HANDS-ON EXERCISE
# ============================================================================

puts "\n" + "=" * 80
puts "11. PRACTICE EXERCISE"
puts "=" * 80

puts "\nGiven this scenario, which method should you use?\n"

scenarios = [
  {
    question: "Load 1000 posts with their authors (just display author name)",
    answer: ".includes(:author) or .preload(:author)",
    reason: "Simple loading, no filtering/sorting needed"
  },
  {
    question: "Show only posts by verified authors",
    answer: ".eager_load(:author).where(users: { verified: true })",
    reason: "Must filter on author table, requires JOIN"
  },
  {
    question: "Load posts with comments and tags (display all data)",
    answer: ".preload(:comments, :tags)",
    reason: "Multiple has_many, avoid cartesian product"
  },
  {
    question: "Sort posts by author name",
    answer: ".eager_load(:author).order('users.name')",
    reason: "Sorting requires JOIN to access users.name"
  },
  {
    question: "Load posts with authors, might add filtering later",
    answer: ".includes(:author)",
    reason: "Let Rails decide, works with future filtering"
  }
]

scenarios.each_with_index do |scenario, i|
  puts "\nScenario #{i + 1}:"
  puts "Q: #{scenario[:question]}"
  puts "A: #{scenario[:answer]}"
  puts "Why: #{scenario[:reason]}"
end

puts "\n" + "=" * 80
puts "END OF GUIDE"
puts "=" * 80
puts "\nRemember: When in doubt, use .includes() - it's the safe default! ✅"
