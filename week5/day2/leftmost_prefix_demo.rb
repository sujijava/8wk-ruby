# ============================================================================
# LEFTMOST PREFIX RULE - Visual Demonstration
# ============================================================================

# Imagine a composite index as a sorted phonebook
# Index on: (last_name, first_name, age)

# The data is physically stored sorted like this:
SORTED_DATA = [
  { last_name: "Anderson", first_name: "Alice",   age: 25 },
  { last_name: "Anderson", first_name: "Bob",     age: 30 },
  { last_name: "Brown",    first_name: "Charlie", age: 35 },
  { last_name: "Brown",    first_name: "David",   age: 28 },
  { last_name: "Smith",    first_name: "Eve",     age: 40 },
  { last_name: "Smith",    first_name: "Frank",   age: 22 },
]

puts "=" * 80
puts "LEFTMOST PREFIX RULE DEMONSTRATION"
puts "=" * 80
puts "\nIndex: (last_name, first_name, age)"
puts "\nData is stored sorted by last_name, then first_name, then age:"
SORTED_DATA.each { |row| puts "  #{row}" }

# ============================================================================
# RULE: Can use leftmost prefixes
# ============================================================================

puts "\n" + "=" * 80
puts "✅ QUERIES THAT CAN USE THIS INDEX"
puts "=" * 80

puts "\n1. WHERE last_name = 'Brown'"
puts "   Uses: first column (last_name)"
puts "   ✅ Index can quickly jump to 'Brown' section"

puts "\n2. WHERE last_name = 'Brown' AND first_name = 'Charlie'"
puts "   Uses: first + second columns"
puts "   ✅ Index can jump to 'Brown', then scan for 'Charlie'"

puts "\n3. WHERE last_name = 'Brown' AND first_name = 'Charlie' AND age = 35"
puts "   Uses: all three columns"
puts "   ✅ Index can jump directly to the exact row"

# ============================================================================
# RULE: CANNOT skip the first column
# ============================================================================

puts "\n" + "=" * 80
puts "❌ QUERIES THAT CANNOT USE THIS INDEX"
puts "=" * 80

puts "\n1. WHERE first_name = 'Alice'"
puts "   ❌ Skips last_name (first column)"
puts "   ❌ Database must scan entire table"
puts "   Why? Data is sorted by last_name first, so 'Alice' could be anywhere"

puts "\n2. WHERE age = 30"
puts "   ❌ Skips last_name and first_name"
puts "   ❌ Database must scan entire table"

puts "\n3. WHERE first_name = 'Alice' AND age = 25"
puts "   ❌ Skips last_name"
puts "   ❌ Database must scan entire table"

# ============================================================================
# REDUNDANT INDEX DETECTION
# ============================================================================

puts "\n" + "=" * 80
puts "FINDING REDUNDANT INDEXES"
puts "=" * 80

indexes = [
  { name: "idx_1", columns: ["last_name", "first_name", "age"] },
  { name: "idx_2", columns: ["last_name", "first_name"] },        # REDUNDANT!
  { name: "idx_3", columns: ["last_name"] },                      # REDUNDANT!
  { name: "idx_4", columns: ["first_name", "age"] },              # NOT redundant
]

puts "\nIndexes on users table:"
indexes.each do |idx|
  puts "  • #{idx[:name]}: (#{idx[:columns].join(', ')})"
end

puts "\nAnalysis:"
puts "  • idx_1: (last_name, first_name, age)"
puts "    Covers queries on:"
puts "      - last_name"
puts "      - last_name + first_name"
puts "      - last_name + first_name + age"

puts "\n  • idx_2: (last_name, first_name) ❌ REDUNDANT"
puts "    Why? idx_1 already covers these queries via leftmost prefix"

puts "\n  • idx_3: (last_name) ❌ REDUNDANT"
puts "    Why? idx_1 already covers queries on just last_name"

puts "\n  • idx_4: (first_name, age) ✅ NOT REDUNDANT"
puts "    Why? Starts with 'first_name', which idx_1 doesn't support alone"

# ============================================================================
# YOUR INVENTORY_LOGS EXAMPLE
# ============================================================================

puts "\n" + "=" * 80
puts "YOUR INVENTORY_LOGS EXAMPLE"
puts "=" * 80

your_indexes = [
  { name: "idx_1", columns: ["product_id", "change_type"] },
  { name: "idx_2", columns: ["product_id"] },                     # REDUNDANT!
  { name: "idx_3", columns: ["created_at"] },                     # NOT redundant
]

puts "\nYour indexes:"
your_indexes.each do |idx|
  puts "  • #{idx[:name]}: (#{idx[:columns].join(', ')})"
end

puts "\nAnalysis:"
puts "  • idx_1: (product_id, change_type)"
puts "    Can handle queries on:"
puts "      - WHERE product_id = ?"
puts "      - WHERE product_id = ? AND change_type = ?"

puts "\n  • idx_2: (product_id) ❌ REDUNDANT"
puts "    Why? idx_1 already handles 'WHERE product_id = ?' via leftmost prefix"
puts "    Impact: Wastes disk space + slows down INSERTs"

puts "\n  • idx_3: (created_at) ✅ NOT REDUNDANT"
puts "    Why? Starts with different column than idx_1"

# ============================================================================
# HOW TO CHECK FOR REDUNDANCY
# ============================================================================

puts "\n" + "=" * 80
puts "ALGORITHM: CHECKING FOR REDUNDANT INDEXES"
puts "=" * 80

puts "\nFor each index A:"
puts "  For each other index B:"
puts "    If B's columns are a LEFT PREFIX of A's columns:"
puts "      → B is REDUNDANT (can be removed)"

puts "\nExample:"
puts "  Index A: (user_id, status, created_at)"
puts "  Index B: (user_id, status)              ← REDUNDANT"
puts "  Index C: (user_id)                      ← REDUNDANT"
puts "  Index D: (status, created_at)           ← NOT redundant (different start)"

# ============================================================================
# PRACTICAL CHECKLIST
# ============================================================================

puts "\n" + "=" * 80
puts "CHECKLIST: FINDING REDUNDANT INDEXES"
puts "=" * 80

puts "\n1. List all indexes on each table"
puts "2. For each pair of indexes:"
puts "   - Check if one is a left prefix of the other"
puts "   - If yes → shorter one is redundant"
puts "3. Consider query patterns:"
puts "   - Sometimes you WANT both for performance reasons"
puts "   - Example: (a, b, c) is huge, but queries often filter just (a)"
puts "   - A separate (a) index might be faster due to smaller size"

# ============================================================================
# EXCEPTION: When Redundancy is OK
# ============================================================================

puts "\n" + "=" * 80
puts "EXCEPTION: When 'Redundant' Indexes Make Sense"
puts "=" * 80

puts "\n1. Covering Indexes:"
puts "   Index A: (user_id, email, name, created_at) -- covering index"
puts "   Index B: (user_id)                          -- smaller, faster for simple queries"

puts "\n2. Index Size:"
puts "   If Index A is very wide (many columns), Index B might scan faster"

puts "\n3. Unique Constraints:"
puts "   Index A: (email, user_id)     -- for queries"
puts "   Index B: (email) UNIQUE       -- for constraint"

puts "\n" + "=" * 80
puts "But 99% of the time: Redundant indexes are just waste!"
puts "=" * 80
