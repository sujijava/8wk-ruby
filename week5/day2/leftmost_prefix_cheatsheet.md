# Leftmost Prefix Rule - Cheat Sheet

## The Rule in One Sentence
**A composite index can ONLY be used if the query filters on the LEFTMOST column(s) in order.**

---

## Visual Guide

```
Index: (A, B, C)

✅ Can Use:
   WHERE A = ?
   WHERE A = ? AND B = ?
   WHERE A = ? AND B = ? AND C = ?
   WHERE A = ? AND C = ?          (uses A only)

❌ Cannot Use:
   WHERE B = ?
   WHERE C = ?
   WHERE B = ? AND C = ?
```

---

## Phonebook Analogy

A composite index `(last_name, first_name)` is like a phonebook:

```
Anderson, Alice
Anderson, Bob
Brown, Charlie
Smith, David
```

**You CAN:**
- Find "Smith" quickly (sorted by last_name)
- Find "Smith, David" quickly (sorted by last_name, then first_name)

**You CANNOT:**
- Find "David" quickly (not sorted by first_name alone)
- You'd have to scan every page!

---

## Redundancy Check Algorithm

```ruby
# Given these indexes:
Index 1: (product_id, status, created_at)
Index 2: (product_id, status)
Index 3: (product_id)
Index 4: (status, created_at)

# Check each pair:
# Is Index 2 a left prefix of Index 1? YES → REDUNDANT ❌
# Is Index 3 a left prefix of Index 1? YES → REDUNDANT ❌
# Is Index 4 a left prefix of Index 1? NO  → NOT redundant ✅
```

**Simple Rule:** If Index B's columns match the **start** of Index A's columns in the same order, Index B is redundant.

---

## Your Specific Error

```ruby
# What you had:
QueryAnalyzer.add_index('inventory_logs', ['product_id', 'change_type'])
QueryAnalyzer.add_index('inventory_logs', 'product_id')  # ❌ REDUNDANT!

# Why redundant?
# The first index already covers queries like:
#   WHERE product_id = ?
# Because product_id is the LEFTMOST column!

# What you need:
QueryAnalyzer.add_index('inventory_logs', ['product_id', 'change_type'])
# Remove the single product_id index
```

---

## Quick Test Questions

**Index: (user_id, status, created_at)**

1. Can it be used for `WHERE user_id = 123`?
   - ✅ Yes (leftmost column)

2. Can it be used for `WHERE user_id = 123 AND status = 'active'`?
   - ✅ Yes (first two columns)

3. Can it be used for `WHERE status = 'active'`?
   - ❌ No (skips user_id)

4. Can it be used for `WHERE user_id = 123 AND created_at > '2024-01-01'`?
   - ⚠️ Partial (uses user_id, then filters created_at)
   - But ORDER BY created_at won't be efficient

5. Is index `(user_id)` redundant?
   - ✅ Yes! The composite index already covers it

6. Is index `(status, created_at)` redundant?
   - ❌ No! Different starting column

---

## Common Mistakes

### ❌ Mistake 1: Creating prefixes of existing indexes
```ruby
add_index(['a', 'b', 'c'])
add_index(['a', 'b'])        # REDUNDANT!
add_index(['a'])             # REDUNDANT!
```

### ❌ Mistake 2: Thinking you need separate single-column indexes
```ruby
# Don't do this:
add_index(['user_id', 'status'])
add_index('user_id')         # Already covered!

# Do this:
add_index(['user_id', 'status'])  # That's all you need
```

### ✅ Correct: Different starting columns
```ruby
add_index(['user_id', 'status'])
add_index(['email'])         # NOT redundant (different start)
add_index(['created_at'])    # NOT redundant (different start)
```

---

## Real-World Impact

On `inventory_logs` table (10M rows, 1000 writes/sec):

**With redundant index:**
- Every INSERT updates 2 indexes: `(product_id, change_type)` AND `(product_id)`
- Cost: 2000 index writes/sec
- Disk space: 2x wasted

**Without redundant index:**
- Every INSERT updates 1 index: `(product_id, change_type)`
- Cost: 1000 index writes/sec
- Disk space: 50% saved
- **Same query performance!**

---

## Summary

1. **Composite indexes are sorted left-to-right**
2. **Queries must use columns from left-to-right (no skipping)**
3. **Single-column index on leftmost column = REDUNDANT**
4. **Check every pair of indexes for left-prefix redundancy**
5. **Remove redundant indexes to save write performance and disk space**

---

## When Reviewing Your Code

Ask yourself for each index pair:
```
1. Do they have the same starting columns?
2. Is one a shorter version of the other?
3. If YES to both → Remove the shorter one!
```
