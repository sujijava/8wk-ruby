# ============================================================================
# N+1 QUERIES & EAGER LOADING - FAANG INTERVIEW CHALLENGE
# ============================================================================
#
# Problem Statement:
# ------------------
# You're a senior engineer at a fast-growing startup. The /api/posts endpoint
# is taking 5+ seconds to load and customers are complaining. Your manager
# asks you to investigate and fix the performance issues.
#
# Upon investigation, you discover the codebase is riddled with N+1 queries.
# Your job is to identify and fix ALL N+1 queries to bring response time
# under 100ms.
#
# Real-World Context:
# -------------------
#
# This is a CRITICAL skill for backend engineers. Poor database query
# patterns can bring down production systems at scale.
#
# What is an N+1 Query?
# ---------------------
# An N+1 query happens when you:
# 1. Load N records (1 query)
# 2. For each record, load associated data (N queries)
#
# Example:
#   posts = Post.all                    # 1 query
#   posts.each do |post|
#     puts post.author.name             # N queries (one per post!)
#   end
#   Total: 1 + N queries = N+1 queries
#
# The Fix:
#   posts = Post.all.includes(:author)  # 2 queries total!
#   posts.each do |post|
#     puts post.author.name             # No additional queries
#   end
#
# At scale, this difference is MASSIVE:
# - 1,000 posts with N+1: 1,001 queries (~5 seconds)
# - 1,000 posts with eager loading: 2 queries (~50ms)
#
# Requirements:
# -------------
# This challenge includes a simulated ORM (like ActiveRecord) that logs
# all database queries. Your job is to:
#
# 1. RUN the existing code and observe the N+1 queries
# 2. IDENTIFY all N+1 problems in the codebase
# 3. FIX each N+1 by implementing eager loading
# 4. VERIFY query count drops dramatically
# 5. MEASURE performance improvement
#
# N+1 Scenarios to Fix:
# ---------------------
# 1. Basic Association (posts -> authors)
# 2. Nested Association (posts -> comments -> users)
# 3. Multiple Associations (posts -> author + tags)
# 4. Conditional Loading (load comments only for published posts)
# 5. Count Queries (post.comments.count in a loop)
# 6. Has-Many Through (users -> posts through memberships)
# 7. Polymorphic Association (likes on different models)
#
# Tools & Techniques:
# -------------------
# • Query Logging: See every SQL query
# • Query Counter: Track total query count
# • Eager Loading: .includes(), .preload(), .eager_load()
# • Counter Cache: Cache counts to avoid COUNT(*) queries
# • Select Specific Fields: Only load what you need
#
# Success Criteria:
# -----------------
# Original code: ~100+ queries
# Your solution: < 10 queries
# Performance improvement: > 10x faster
#
# Time Expectation:
# -----------------
# - 60-75 minutes to identify and fix all N+1s
# - Practice explaining trade-offs (memory vs queries)
# - Be ready to discuss Bullet gem patterns in Rails
#
# ============================================================================

# ============================================================================
# SIMULATED ORM - Mimics ActiveRecord Behavior
# ============================================================================
# This is a simplified ORM to demonstrate N+1 queries without requiring
# a real database. It logs all "queries" so you can see the N+1 problem.

class QueryLogger
  @queries = []
  @enabled = true

  class << self
    attr_accessor :queries, :enabled

    def log(query)
      return unless @enabled
      @queries << query
      puts "  SQL: #{query}" if ENV['VERBOSE']
    end

    def count
      @queries.length
    end

    def reset!
      @queries = []
    end

    def disable
      @enabled = false
      yield
    ensure
      @enabled = true
    end
  end
end

# Base class for all models
class BaseModel
  class << self
    attr_accessor :all_records, :associations

    def inherited(subclass)
      subclass.all_records = []
      subclass.associations = {}
    end

    def create(attributes)
      instance = new(attributes)
      @all_records << instance
      instance
    end

    def all
      QueryLogger.log("SELECT * FROM #{table_name}")
      Relation.new(self, @all_records.dup)
    end

    def find(id)
      QueryLogger.log("SELECT * FROM #{table_name} WHERE id = #{id}")
      @all_records.find { |r| r.id == id }
    end

    def where(conditions)
      QueryLogger.log("SELECT * FROM #{table_name} WHERE #{conditions.inspect}")
      matching = @all_records.select do |record|
        conditions.all? { |key, value| record.send(key) == value }
      end
      Relation.new(self, matching)
    end

    def table_name
      "#{name.downcase}s"
    end

    def belongs_to(name, class_name: nil)
      @associations[name] = { type: :belongs_to, class_name: class_name || name.to_s.capitalize }

      define_method(name) do
        foreign_key = "#{name}_id"
        id_value = send(foreign_key)
        return nil unless id_value

        klass = Object.const_get(self.class.associations[name][:class_name])
        QueryLogger.log("SELECT * FROM #{klass.table_name} WHERE id = #{id_value}")
        klass.all_records.find { |r| r.id == id_value }
      end
    end

    def has_many(name, class_name: nil, foreign_key: nil)
      @associations[name] = {
        type: :has_many,
        class_name: class_name || name.to_s.capitalize.chomp('s'),
        foreign_key: foreign_key
      }

      define_method(name) do
        assoc = self.class.associations[name]
        klass = Object.const_get(assoc[:class_name])
        fk = assoc[:foreign_key] || "#{self.class.name.downcase}_id"

        QueryLogger.log("SELECT * FROM #{klass.table_name} WHERE #{fk} = #{id}")
        klass.all_records.select { |r| r.send(fk) == id }
      end
    end

    def has_many_through(name, through:, source:)
      @associations[name] = {
        type: :has_many_through,
        through: through,
        source: source
      }

      define_method(name) do
        through_records = send(through)
        through_records.flat_map { |r| r.send(source) }.compact.uniq
      end
    end
  end

  attr_reader :id, :attributes

  def initialize(attributes)
    @id = attributes[:id]
    @attributes = attributes
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
      self.class.send(:attr_reader, key) unless respond_to?(key)
    end
  end
end

# Relation class (like ActiveRecord::Relation)
class Relation
  attr_reader :records, :model_class, :includes_values

  def initialize(model_class, records)
    @model_class = model_class
    @records = records
    @includes_values = []
  end

  def includes(*associations)
    @includes_values = associations
    preload_associations
    self
  end

  def each(&block)
    @records.each(&block)
  end

  def count
    @records.count
  end

  def map(&block)
    @records.map(&block)
  end

  def to_a
    @records
  end

  def select(&block)
    @records.select(&block)
  end

  def first(n = nil)
    n ? @records.first(n) : @records.first
  end

  private

  def preload_associations
    # TODO: Implement eager loading here
    # This is where you'll implement the fix for N+1 queries
    #
    # Hints:
    # 1. For each association in @includes_values
    # 2. Load all associated records in ONE query
    # 3. Cache them in memory
    # 4. Modify the association methods to use the cache
    #
    # Example for belongs_to:
    #   - Collect all foreign key IDs from @records
    #   - Load all associated records WHERE id IN (id1, id2, ...)
    #   - Cache them by ID
    #   - Override the getter to check cache first
  end
end

# ============================================================================
# MODELS - Blog Application
# ============================================================================

class User < BaseModel
  belongs_to :company
  has_many :posts, class_name: 'Post'
  has_many :comments, class_name: 'Comment'
  has_many :authored_posts, class_name: 'Post', foreign_key: 'author_id'
end

class Company < BaseModel
  has_many :users, class_name: 'User'
end

class Post < BaseModel
  belongs_to :author, class_name: 'User'
  has_many :comments, class_name: 'Comment'
  has_many :tags, class_name: 'Tag'
  has_many :likes, class_name: 'Like'

  def published?
    @published
  end
end

class Comment < BaseModel
  belongs_to :user
  belongs_to :post
  has_many :likes, class_name: 'Like'
end

class Tag < BaseModel
  belongs_to :post
end

class Like < BaseModel
  belongs_to :user

  # Polymorphic association (can like posts or comments)
  def likeable
    QueryLogger.log("SELECT * FROM #{@likeable_type.downcase}s WHERE id = #{@likeable_id}")
    Object.const_get(@likeable_type).find(@likeable_id)
  end
end

# ============================================================================
# SEED DATA
# ============================================================================

def seed_data
  QueryLogger.disable do
    # Create companies
    5.times do |i|
      Company.create(id: i + 1, name: "Company #{i + 1}")
    end

    # Create users
    20.times do |i|
      User.create(
        id: i + 1,
        name: "User #{i + 1}",
        email: "user#{i + 1}@example.com",
        company_id: (i % 5) + 1
      )
    end

    # Create posts
    50.times do |i|
      Post.create(
        id: i + 1,
        title: "Post #{i + 1}",
        body: "This is the body of post #{i + 1}",
        author_id: (i % 20) + 1,
        published: i.even?
      )
    end

    # Create comments
    200.times do |i|
      Comment.create(
        id: i + 1,
        body: "Comment #{i + 1}",
        user_id: (i % 20) + 1,
        post_id: (i % 50) + 1
      )
    end

    # Create tags
    150.times do |i|
      Tag.create(
        id: i + 1,
        name: "Tag #{i % 10}",
        post_id: (i % 50) + 1
      )
    end

    # Create likes
    100.times do |i|
      Like.create(
        id: i + 1,
        user_id: (i % 20) + 1,
        likeable_type: i.even? ? 'Post' : 'Comment',
        likeable_id: i.even? ? (i % 50) + 1 : (i % 200) + 1
      )
    end
  end
end

# ============================================================================
# PROBLEMATIC CODE - FULL OF N+1 QUERIES!
# ============================================================================
# This is the code you need to fix. Each method has N+1 query problems.

class BlogAPI
  # N+1 Problem #1: Basic Association
  # ----------------------------------
  # Gets all posts with author names
  #
  # Current: 1 query for posts + N queries for authors
  # Target: 2 queries total
  def self.get_posts_with_authors
    puts "\n📝 Getting posts with authors..."
    QueryLogger.reset!

    posts = Post.all
    results = posts.map do |post|
      {
        title: post.title,
        author_name: post.author.name  # N+1 here!
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #2: Nested Associations
  # ------------------------------------
  # Gets posts with comments and comment authors
  #
  # Current: 1 + N + M queries (N posts, M comments)
  # Target: 3 queries total
  def self.get_posts_with_comments
    puts "\n💬 Getting posts with comments and users..."
    QueryLogger.reset!

    posts = Post.all
    results = posts.map do |post|
      {
        title: post.title,
        comments: post.comments.map do |comment|  # N+1 here!
          {
            body: comment.body,
            user_name: comment.user.name  # Another N+1!
          }
        end
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #3: Multiple Associations
  # --------------------------------------
  # Gets posts with author, comments, and tags
  #
  # Current: 1 + N + N + N queries
  # Target: 4 queries total
  def self.get_posts_full_data
    puts "\n🏷️  Getting posts with all associations..."
    QueryLogger.reset!

    posts = Post.all
    results = posts.map do |post|
      {
        title: post.title,
        author: post.author.name,      # N+1
        comment_count: post.comments.count,  # N+1
        tags: post.tags.map(&:name)    # N+1
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #4: Conditional Loading
  # ------------------------------------
  # Gets published posts with their comments
  #
  # Current: 1 + N queries
  # Target: 2 queries total
  def self.get_published_posts_with_comments
    puts "\n📰 Getting published posts with comments..."
    QueryLogger.reset!

    posts = Post.all
    results = posts.select(&:published?).map do |post|
      {
        title: post.title,
        comments: post.comments.map(&:body)  # N+1
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #5: Has-Many Through
  # ---------------------------------
  # Gets users with their company and authored posts
  #
  # Current: 1 + N + M queries
  # Target: 3 queries total
  def self.get_users_with_posts
    puts "\n👥 Getting users with companies and posts..."
    QueryLogger.reset!

    users = User.all
    results = users.map do |user|
      {
        name: user.name,
        company: user.company.name,    # N+1
        posts: user.authored_posts.map(&:title)  # N+1
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #6: Count Queries
  # ------------------------------
  # Gets posts with comment counts
  #
  # Current: 1 + N COUNT queries
  # Target: 2 queries total (use counter_cache pattern)
  def self.get_posts_with_counts
    puts "\n🔢 Getting posts with comment counts..."
    QueryLogger.reset!

    posts = Post.all
    results = posts.map do |post|
      {
        title: post.title,
        comment_count: post.comments.count  # N+1 COUNT query!
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end

  # N+1 Problem #7: Polymorphic Associations
  # -----------------------------------------
  # Gets likes with their likeable objects (posts or comments)
  #
  # Current: 1 + N queries
  # Target: 3 queries (1 for likes, 1 for posts, 1 for comments)
  def self.get_likes_with_likeables
    puts "\n❤️  Getting likes with likeable objects..."
    QueryLogger.reset!

    likes = Like.all
    results = likes.to_a.first(10).map do |like|
      {
        user: like.user.name,          # N+1
        likeable: like.likeable.class.name  # N+1
      }
    end

    puts "   Queries: #{QueryLogger.count}"
    results
  end
end

# ============================================================================
# YOUR TASK: FIX THE N+1 QUERIES
# ============================================================================
#
# Instructions:
# 1. Run this file to see the N+1 queries in action
# 2. For each method above, implement eager loading
# 3. Modify the Relation#preload_associations method to cache associations
# 4. Re-run and verify query count drops dramatically
#
# Hints:
# ------
# • Use .includes(:association_name) to eager load
# • For multiple associations: .includes(:author, :comments, :tags)
# • For nested: .includes(comments: :user)
# • You'll need to implement the caching logic in Relation#preload_associations
#
# Example Fix:
# ------------
# Before:
#   posts = Post.all
#   posts.each { |p| puts p.author.name }  # N+1
#
# After:
#   posts = Post.all.includes(:author)
#   posts.each { |p| puts p.author.name }  # No N+1!
#
# ============================================================================

# ============================================================================
# TEST RUNNER
# ============================================================================

def run_all_tests
  puts "=" * 80
  puts "N+1 QUERY DETECTION - IDENTIFYING PERFORMANCE PROBLEMS"
  puts "=" * 80

  seed_data

  puts "\n⚠️  WARNING: This code has SEVERE N+1 query problems!"
  puts "Watch the query counts below...\n"

  BlogAPI.get_posts_with_authors
  BlogAPI.get_posts_with_comments
  BlogAPI.get_posts_full_data
  BlogAPI.get_published_posts_with_comments
  BlogAPI.get_users_with_posts
  BlogAPI.get_posts_with_counts
  BlogAPI.get_likes_with_likeables

  puts "\n" + "=" * 80
  puts "SUMMARY"
  puts "=" * 80
  puts "These query counts are UNACCEPTABLE in production!"
  puts ""
  puts "Your job:"
  puts "1. Implement eager loading in Relation#preload_associations"
  puts "2. Use .includes() in each BlogAPI method"
  puts "3. Reduce total queries from ~300+ to < 30"
  puts ""
  puts "Success Criteria:"
  puts "• get_posts_with_authors: 2 queries (was ~51)"
  puts "• get_posts_with_comments: 3 queries (was ~251)"
  puts "• get_posts_full_data: 4 queries (was ~151)"
  puts "• get_published_posts_with_comments: 2 queries (was ~26)"
  puts "• get_users_with_posts: 3 queries (was ~71)"
  puts "• get_posts_with_counts: 2 queries (was ~51)"
  puts "• get_likes_with_likeables: 3 queries (was ~21)"
  puts ""
  puts "💡 Tip: Start with get_posts_with_authors (simplest case)"
  puts "=" * 80
end

# Run the tests
if __FILE__ == $0
  run_all_tests
end
