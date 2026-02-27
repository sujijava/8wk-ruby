# ============================================================================
# DATABASE INDEXING OPTIMIZATION - PRODUCTION SCHEMA REVIEW
# ============================================================================
#
# Problem Statement:
# ------------------
# You're a senior backend engineer at an e-commerce company. The database team
# has escalated that several critical queries are causing table scans and
# severely degrading performance. Peak traffic shows queries taking 5-10 seconds
# that should complete in under 100ms.
#
# Your task is to review the schema, identify missing indexes, add appropriate
# indexes, and explain your composite index ordering decisions.
#
# Real-World Context:
# -------------------
# Database indexing is a CRITICAL skill that separates junior from senior engineers.
# Poor indexing can:
# • Cause production outages during peak traffic
# • Lead to table scans on multi-million row tables
# • Result in query timeouts and degraded user experience
# • Waste thousands in database costs
#
# At scale, the difference is dramatic:
# • Without index: 5,000ms query time (full table scan)
# • With proper index: 5ms query time (index seek)
#
# This is a 1000x performance improvement!
#
# What is a Database Index?
# -------------------------
# An index is a data structure (usually B-tree) that allows fast lookups.
# Think of it like a book's index - instead of reading every page to find
# a topic, you look it up in the index.
#
# Types of Indexes:
# • Single-column index: CREATE INDEX idx_email ON users(email)
# • Composite index: CREATE INDEX idx_status_created ON orders(status, created_at)
# • Unique index: CREATE UNIQUE INDEX idx_unique_email ON users(email)
# • Partial index: CREATE INDEX idx_active_users ON users(email) WHERE active = true
#
# Composite Index Ordering Rules:
# --------------------------------
# The order of columns in a composite index is CRITICAL!
#
# Rule 1: Equality First, Range Last
#   WHERE status = 'pending' AND created_at > '2024-01-01'
#   Index: (status, created_at) ✓  NOT (created_at, status) ✗
#
# Rule 2: Most Selective First (for multiple equalities)
#   WHERE user_id = 123 AND status = 'shipped'
#   If user_id is more selective: (user_id, status) ✓
#
# Rule 3: Support Common Query Patterns
#   If queries often filter by A then B: (A, B)
#   If queries often filter by B alone: need separate index on B
#
# Rule 4: Leftmost Prefix Rule
#   Index on (A, B, C) can be used for:
#   • WHERE A = ?
#   • WHERE A = ? AND B = ?
#   • WHERE A = ? AND B = ? AND C = ?
#   But NOT for:
#   • WHERE B = ?
#   • WHERE C = ?
#   • WHERE B = ? AND C = ?
#
# When NOT to Index:
# ------------------
# • Small tables (< 1000 rows) - sequential scan is faster
# • Columns with low selectivity (booleans in large tables)
# • Columns frequently updated (indexes slow down writes)
# • Too many indexes on write-heavy tables (INSERT/UPDATE overhead)
#
# Requirements:
# -------------
# 1. ANALYZE the schema and slow query patterns
# 2. IDENTIFY which queries need indexes
# 3. DESIGN appropriate indexes (single-column vs composite)
# 4. EXPLAIN composite index column ordering decisions
# 5. DISCUSS trade-offs (read performance vs write overhead)
#
# Success Criteria:
# -----------------
# • All slow queries < 10ms
# • Proper composite index ordering
# • No redundant indexes
# • Clear explanation of design decisions
#
# Time Expectation:
# -----------------
# • 45-60 minutes to analyze and design indexes
# • Be ready to explain your reasoning in detail
#
# ============================================================================

require 'set'

# ============================================================================
# SIMULATED DATABASE - Query Analyzer & Index Manager
# ============================================================================

class QueryAnalyzer
  @queries_executed = []
  @indexes = {}

  class << self
    attr_accessor :queries_executed, :indexes

    def execute_query(sql, table, conditions, order_by = nil)
      execution_time = estimate_query_time(table, conditions, order_by)
      scan_type = determine_scan_type(table, conditions, order_by)
      rows_examined = estimate_rows_examined(table, conditions)

      query_info = {
        sql: sql,
        table: table,
        execution_time_ms: execution_time,
        scan_type: scan_type,
        rows_examined: rows_examined,
        conditions: conditions,
        order_by: order_by
      }

      @queries_executed << query_info

      puts "\n#{sql}"
      puts "  Scan type: #{scan_type}"
      puts "  Rows examined: #{rows_examined}"
      puts "  Execution time: #{execution_time}ms"
      puts "  #{execution_time > 100 ? '🔴 SLOW QUERY!' : '🟢 Fast'}"

      query_info
    end

    def add_index(table, columns, unique: false, name: nil)
      columns = [columns] unless columns.is_a?(Array)
      index_name = name || "idx_#{table}_#{columns.join('_')}"

      @indexes[table] ||= []
      @indexes[table] << {
        name: index_name,
        columns: columns,
        unique: unique
      }

      puts "\n✅ Created index: #{index_name} on #{table}(#{columns.join(', ')})"
    end

    def reset!
      @queries_executed = []
      @indexes = {}
    end

    def print_query_summary
      total_time = @queries_executed.sum { |q| q[:execution_time_ms] }
      slow_queries = @queries_executed.select { |q| q[:execution_time_ms] > 100 }

      puts "\n" + "=" * 80
      puts "QUERY PERFORMANCE SUMMARY"
      puts "=" * 80
      puts "Total queries: #{@queries_executed.count}"
      puts "Slow queries (>100ms): #{slow_queries.count}"
      puts "Total execution time: #{total_time}ms"
      puts "Average query time: #{@queries_executed.count > 0 ? (total_time / @queries_executed.count).round(2) : 0}ms"

      if slow_queries.any?
        puts "\n🔴 SLOW QUERIES DETECTED:"
        slow_queries.each do |q|
          puts "  • #{q[:sql]} (#{q[:execution_time_ms]}ms, #{q[:scan_type]})"
        end
      end
      puts "=" * 80
    end

    def print_index_coverage
      puts "\n" + "=" * 80
      puts "CURRENT INDEX COVERAGE"
      puts "=" * 80

      if @indexes.empty?
        puts "⚠️  NO INDEXES FOUND - All queries using table scans!"
      else
        @indexes.each do |table, indexes|
          puts "\nTable: #{table}"
          indexes.each do |idx|
            puts "  • #{idx[:name]}: (#{idx[:columns].join(', ')})#{idx[:unique] ? ' UNIQUE' : ''}"
          end
        end
      end
      puts "=" * 80
    end

    private

    def estimate_query_time(table, conditions, order_by)
      # Simulate query execution time based on index coverage
      has_usable_index = false
      index_selectivity = 1.0

      if @indexes[table]
        # Check if any index can be used
        @indexes[table].each do |idx|
          # Leftmost prefix matching
          condition_columns = conditions.keys

          # Check if index covers the conditions (leftmost prefix rule)
          if idx[:columns].first == condition_columns.first
            has_usable_index = true
            # Better index = lower selectivity multiplier
            index_selectivity = 0.1 / idx[:columns].length
            break
          end
        end
      end

      base_time = TABLE_SIZES[table] || 1000

      if has_usable_index
        # Index seek: very fast
        (base_time * index_selectivity).round
      else
        # Table scan: slow!
        (base_time * 5).round
      end
    end

    def determine_scan_type(table, conditions, order_by)
      return "TABLE SCAN (no indexes)" if @indexes[table].nil? || @indexes[table].empty?

      condition_columns = conditions.keys

      # Check for usable index
      usable_index = @indexes[table].find do |idx|
        # Leftmost prefix rule
        idx[:columns].first == condition_columns.first
      end

      if usable_index
        if usable_index[:columns] == condition_columns
          "INDEX SEEK (perfect match)"
        else
          "INDEX SEEK + FILTER (partial match)"
        end
      else
        "TABLE SCAN (no usable index)"
      end
    end

    def estimate_rows_examined(table, conditions)
      total_rows = TABLE_SIZES[table] || 1000

      # If indexed, examine fewer rows
      if @indexes[table]&.any?
        (total_rows * 0.05).round
      else
        total_rows
      end
    end
  end
end

# Table sizes (simulating production data volumes)
TABLE_SIZES = {
  'users' => 500_000,
  'orders' => 2_000_000,
  'order_items' => 5_000_000,
  'products' => 100_000,
  'reviews' => 1_500_000,
  'inventory_logs' => 10_000_000,
  'sessions' => 3_000_000
}

# ============================================================================
# DATABASE SCHEMA
# ============================================================================
#
# This is the current production schema. NO INDEXES have been added yet
# (except automatic primary keys).
#
# Your job: Add appropriate indexes to optimize the slow queries below.
#

SCHEMA = <<~SQL
  -- Users table (500K rows)
  CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    status VARCHAR(50),  -- 'active', 'inactive', 'suspended'
    created_at TIMESTAMP,
    last_login_at TIMESTAMP,
    country_code VARCHAR(2)
  );
  # index on email 
  # unique constraint to email
  # index - user_id + status
  # index - created at 

  -- Orders table (2M rows)
  CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    status VARCHAR(50),  -- 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
    total_amount DECIMAL(10,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    shipped_at TIMESTAMP,
    payment_method VARCHAR(50)
  );
  # index- created at
  # index - s

  -- Order Items table (5M rows)
  CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER,
    price DECIMAL(10,2),
    created_at TIMESTAMP
  );

  -- Products table (100K rows)
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(255),
    category VARCHAR(100),
    price DECIMAL(10,2),
    stock_quantity INTEGER,
    status VARCHAR(50),  -- 'active', 'discontinued', 'out_of_stock'
    created_at TIMESTAMP
  );

  -- Reviews table (1.5M rows)
  CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating INTEGER,  -- 1-5
    status VARCHAR(50),  -- 'pending', 'approved', 'rejected'
    created_at TIMESTAMP,
    helpful_count INTEGER
  );

  -- Inventory Logs table (10M rows) - tracks all inventory changes
  CREATE TABLE inventory_logs (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    change_type VARCHAR(50),  -- 'restock', 'sale', 'return', 'adjustment'
    quantity_change INTEGER,
    created_at TIMESTAMP,
    created_by INTEGER
  );

  -- Sessions table (3M rows) - user session tracking
  CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(50),
    created_at TIMESTAMP,
    expires_at TIMESTAMP,
    last_activity_at TIMESTAMP
  );
SQL

# ============================================================================
# SLOW QUERIES - These are real production queries causing problems
# ============================================================================

class SlowQueries
  # Query 1: User Login
  # --------------------
  # Frequency: 10,000 requests/minute
  # Current performance: 3,500ms
  # Target: < 5ms
  #
  # This query runs on EVERY login attempt
  def self.find_user_by_email(email)
    QueryAnalyzer.execute_query(
      "SELECT * FROM users WHERE email = '#{email}'",
      'users',
      { email: email }
    )
  end

  # Query 2: Recent Orders Dashboard
  # ---------------------------------
  # Frequency: 5,000 requests/minute
  # Current performance: 8,000ms
  # Target: < 50ms
  #
  # Fetches recent orders for a user, filtered by status
  def self.get_user_orders(user_id, status = 'processing')
    QueryAnalyzer.execute_query(
      "SELECT * FROM orders WHERE user_id = #{user_id} AND status = '#{status}' ORDER BY created_at DESC",
      'orders',
      { user_id: user_id, status: status },
      'created_at DESC'
    )
  end

  # Query 3: Admin Order Search
  # ----------------------------
  # Frequency: 100 requests/minute
  # Current performance: 12,000ms
  # Target: < 100ms
  #
  # Admin panel: find orders by status and date range
  def self.find_orders_by_status_and_date(status, start_date)
    QueryAnalyzer.execute_query(
      "SELECT * FROM orders WHERE status = '#{status}' AND created_at >= '#{start_date}' ORDER BY created_at DESC",
      'orders',
      { status: status, created_at: start_date },
      'created_at DESC'
    )
  end

  # Query 4: Product Lookup by SKU
  # -------------------------------
  # Frequency: 15,000 requests/minute
  # Current performance: 2,800ms
  # Target: < 5ms
  #
  # Inventory system looks up products by SKU constantly
  def self.find_product_by_sku(sku)
    QueryAnalyzer.execute_query(
      "SELECT * FROM products WHERE sku = '#{sku}'",
      'products',
      { sku: sku }
    )
  end

  # Query 5: Product Reviews
  # -------------------------
  # Frequency: 2,000 requests/minute
  # Current performance: 6,500ms
  # Target: < 50ms
  #
  # Product page shows approved reviews for a product
  def self.get_product_reviews(product_id)
    QueryAnalyzer.execute_query(
      "SELECT * FROM reviews WHERE product_id = #{product_id} AND status = 'approved' ORDER BY created_at DESC",
      'reviews',
      { product_id: product_id, status: 'approved' },
      'created_at DESC'
    )
  end

  # Query 6: Inventory History
  # ---------------------------
  # Frequency: 500 requests/minute
  # Current performance: 45,000ms (45 seconds!)
  # Target: < 200ms
  #
  # Warehouse team checks inventory changes for products
  def self.get_inventory_history(product_id, change_type = nil)
    if change_type
      QueryAnalyzer.execute_query(
        "SELECT * FROM inventory_logs WHERE product_id = #{product_id} AND change_type = '#{change_type}' ORDER BY created_at DESC",
        'inventory_logs',
        { product_id: product_id, change_type: change_type },
        'created_at DESC'
      )
    else
      QueryAnalyzer.execute_query(
        "SELECT * FROM inventory_logs WHERE product_id = #{product_id} ORDER BY created_at DESC",
        'inventory_logs',
        { product_id: product_id },
        'created_at DESC'
      )
    end
  end

  # Query 7: Active Sessions Cleanup
  # ---------------------------------
  # Frequency: Runs every minute (background job)
  # Current performance: 15,000ms
  # Target: < 100ms
  #
  # Background job to find and delete expired sessions
  def self.find_expired_sessions(current_time)
    QueryAnalyzer.execute_query(
      "SELECT * FROM sessions WHERE expires_at < '#{current_time}'",
      'sessions',
      { expires_at: current_time }
    )
  end

  # Query 8: Session Validation
  # ----------------------------
  # Frequency: 50,000 requests/minute (every API call!)
  # Current performance: 4,200ms
  # Target: < 5ms
  #
  # Validates user session on EVERY authenticated API request
  def self.validate_session(session_token)
    QueryAnalyzer.execute_query(
      "SELECT * FROM sessions WHERE session_token = '#{session_token}' AND expires_at > NOW()",
      'sessions',
      { session_token: session_token, expires_at: 'NOW()' }
    )
  end

  # Query 9: Order Items Report
  # ----------------------------
  # Frequency: 50 requests/minute
  # Current performance: 22,000ms
  # Target: < 200ms
  #
  # Analytics: Get all items for orders placed after a date
  def self.get_recent_order_items(product_id, start_date)
    QueryAnalyzer.execute_query(
      "SELECT * FROM order_items WHERE product_id = #{product_id} AND created_at >= '#{start_date}'",
      'order_items',
      { product_id: product_id, created_at: start_date }
    )
  end

  # Query 10: Products by Category
  # -------------------------------
  # Frequency: 3,000 requests/minute
  # Current performance: 4,500ms
  # Target: < 50ms
  #
  # Product listing page filtered by category and status
  def self.get_active_products_by_category(category)
    QueryAnalyzer.execute_query(
      "SELECT * FROM products WHERE category = '#{category}' AND status = 'active' ORDER BY created_at DESC",
      'products',
      { category: category, status: 'active' },
      'created_at DESC'
    )
  end
end

# ============================================================================
# YOUR TASK: ADD INDEXES TO OPTIMIZE THESE QUERIES
# ============================================================================
#
# Instructions:
# -------------
# 1. RUN this file to see the current slow query performance
# 2. ANALYZE each query and identify what indexes are needed
# 3. ADD indexes using QueryAnalyzer.add_index(table, columns)
# 4. RE-RUN to verify performance improvements
# 5. EXPLAIN your composite index ordering decisions in comments
#
# For each index you add, answer these questions in a comment:
# • Why is this index needed?
# • Why this column order for composite indexes?
# • What queries does it optimize?
# • Any trade-offs? (write overhead, disk space, etc.)
#
# Example:
# --------
# # Index for Query 1 (find_user_by_email)
# # - Single column index on email (high selectivity)
# # - Used for: user login, password reset, email verification
# # - Trade-off: Adds ~50ms to user registration (acceptable)
# QueryAnalyzer.add_index('users', 'email', unique: true)
#
# # Index for Query 2 (get_user_orders)
# # - Composite: (user_id, status, created_at)
# # - Order: user_id first (equality), status second (equality),
# #          created_at last (range + ORDER BY)
# # - Follows rule: equality conditions before range conditions
# # - Also supports: queries filtering only by user_id (leftmost prefix)
# QueryAnalyzer.add_index('orders', ['user_id', 'status', 'created_at'])
#
# Add your indexes below:
# ============================================================================

def add_indexes
  # TODO: Add your indexes here
  #
  # Use: QueryAnalyzer.add_index(table, columns, unique: false, name: nil)
  #
  # Examples:
  # QueryAnalyzer.add_index('users', 'email', unique: true)
  # QueryAnalyzer.add_index('orders', ['user_id', 'status', 'created_at'])

  puts "\n" + "=" * 80
  puts "ADDING INDEXES"
  puts "=" * 80

  # ====== YOUR INDEXES GO HERE ======

  # Adding Index
  QueryAnalyzer.add_index('users', 'email', unique: true)

  QueryAnalyzer.add_index('orders', ['user_id', 'status'])
  QueryAnalyzer.add_index('orders', 'created_at')
  QueryAnalyzer.add_index('orders', ['status', 'start_date']) # might skip - call number small 

  QueryAnalyzer.add_index('products', 'sku')

  QueryAnalyzer.add_index('reviews', ['product_id', 'status'])
  QueryAnalyzer.add_index('created_at')


  QueryAnalyzer.add_index('inventory_logs', ['product_id', 'change_type'])
  QueryAnalyzer.add_index('inventory_logs', 'created_at')
  QueryAnalyzer.add_index('inventory_logs', 'product_id')


  QueryAnalyzer.add_index('sessions', 'expires_at')
  QueryAnalyzer.add_index('sessions', ['session_token', 'expires_at'])

  QueryAnalyzer.add_index('order_items', ['product_id', 'created_at'])
  
  QueryAnalyzer.add_index('products', ['category', 'status', 'created_at'])


  # ==================================

  puts "\n✅ Index creation complete!"
end

# ============================================================================
# BONUS CHALLENGES
# ============================================================================
#
# After optimizing the basic queries, consider these advanced scenarios:
#
# 1. Partial Indexes:
#    - Some queries only care about active users or approved reviews
#    - Can you use partial indexes? (Hint: WHERE clause in CREATE INDEX)
#
# 2. Covering Indexes:
#    - Include non-key columns in index to avoid table lookups
#    - PostgreSQL: CREATE INDEX ... INCLUDE (extra_columns)
#
# 3. Index Redundancy:
#    - If you have indexes on (A, B, C) and (A, B), the latter is redundant
#    - Identify and remove redundant indexes
#
# 4. Write Performance:
#    - Calculate: if orders table gets 1000 INSERTs/sec, how many
#      additional write operations do your indexes add?
#
# 5. Index Size:
#    - Estimate: if each index entry is ~50 bytes, how much disk space
#      do your indexes consume?
#
# ============================================================================

# ============================================================================
# QUESTIONS TO ANSWER (Write your answers as comments)
# ============================================================================
#
# Answer these questions about your indexing decisions:
#
# Q1: Why did you choose (status, created_at) vs (created_at, status)
#     for the orders table?
#
# A1: [Your answer here]
#
#
# Q2: The sessions table has queries filtering by both session_token and
#     expires_at. Do you need separate indexes or one composite? Why?
#
# A2: [Your answer here]
#
#
# Q3: The inventory_logs table is write-heavy (1000s of INSERTs/sec).
#     How does this affect your indexing strategy?
#
# A3: [Your answer here]
#
#
# Q4: Should you index the 'status' column alone on the orders table?
#     Why or why not?
#
# A4: [Your answer here]
#
#
# Q5: Explain the leftmost prefix rule and give an example from your indexes.
#
# A5: [Your answer here]
#
#
# ============================================================================

# ============================================================================
# TEST RUNNER
# ============================================================================

def run_performance_test
  puts "=" * 80
  puts "DATABASE INDEX OPTIMIZATION CHALLENGE"
  puts "=" * 80
  puts "\nCurrent Schema:"
  puts SCHEMA
  puts "\n" + "=" * 80

  puts "RUNNING SLOW QUERIES (BEFORE OPTIMIZATION)"
  puts "=" * 80

  QueryAnalyzer.reset!

  # # Single-column index
  # QueryAnalyzer.add_index('table_name', 'column_name')

  # # Single-column UNIQUE index
  # QueryAnalyzer.add_index('table_name', 'column_name', unique: true)

  # # Composite index (multiple columns)
  # QueryAnalyzer.add_index('table_name', ['column1', 'column2', 'column3'])

  # # Composite index with custom name
  # QueryAnalyzer.add_index('table_name', ['col1', 'col2'], name: 'idx_custom_name'


  # Execute all slow queries
  SlowQueries.find_user_by_email('user@example.com')
  SlowQueries.get_user_orders(12345, 'processing')
  SlowQueries.find_orders_by_status_and_date('shipped', '2024-01-01')
  SlowQueries.find_product_by_sku('SKU-123456')
  SlowQueries.get_product_reviews(789)
  SlowQueries.get_inventory_history(456, 'restock')
  SlowQueries.find_expired_sessions('2024-01-29')
  SlowQueries.validate_session('abc123token')
  SlowQueries.get_recent_order_items(999, '2024-01-01')
  SlowQueries.get_active_products_by_category('electronics')

  QueryAnalyzer.print_query_summary
  QueryAnalyzer.print_index_coverage

  puts "\n" + "=" * 80
  puts "NOW IT'S YOUR TURN!"
  puts "=" * 80
  puts "1. Add indexes using add_indexes() function"
  puts "2. Re-run this script to see performance improvements"
  puts "3. Answer the questions at the bottom"
  puts "4. Explain your composite index ordering decisions"
  puts "\nTarget Performance:"
  puts "  • All queries should be < 100ms"
  puts "  • Critical queries (login, session) < 10ms"
  puts "  • Use INDEX SEEK, not TABLE SCAN"
  puts "=" * 80

  # Add indexes
  add_indexes

  puts "\n" + "=" * 80
  puts "RE-RUNNING QUERIES (AFTER OPTIMIZATION)"
  puts "=" * 80

  QueryAnalyzer.reset!
  QueryAnalyzer.queries_executed.clear

  # Re-execute all queries
  SlowQueries.find_user_by_email('user@example.com')
  SlowQueries.get_user_orders(12345, 'processing')
  SlowQueries.find_orders_by_status_and_date('shipped', '2024-01-01')
  SlowQueries.find_product_by_sku('SKU-123456')
  SlowQueries.get_product_reviews(789)
  SlowQueries.get_inventory_history(456, 'restock')
  SlowQueries.find_expired_sessions('2024-01-29')
  SlowQueries.validate_session('abc123token')
  SlowQueries.get_recent_order_items(999, '2024-01-01')
  SlowQueries.get_active_products_by_category('electronics')

  QueryAnalyzer.print_query_summary

  puts "\n" + "=" * 80
  puts "PERFORMANCE IMPROVEMENT ANALYSIS"
  puts "=" * 80
  puts "Review the before/after query times above."
  puts "All queries should now use INDEX SEEK instead of TABLE SCAN."
  puts "\nDon't forget to:"
  puts "  1. Explain your composite index ordering"
  puts "  2. Answer the questions at the bottom"
  puts "  3. Discuss trade-offs (read perf vs write overhead)"
  puts "=" * 80
end

# Run the test
if __FILE__ == $0
  run_performance_test
end
