# ============================================================================
# ROMAN NUMERAL CONVERTER
# ============================================================================
#
# Problem Statement:
# ------------------
# Build a bidirectional Roman numeral converter that converts between
# integers and Roman numerals. This exercise focuses on test-driven
# development (TDD) practices using strict red-green-refactor cycles.
#
# Your implementation should handle:
# - Integer to Roman conversion (e.g., 1994 → "MCMXCIV")
# - Roman to Integer conversion (e.g., "MCMXCIV" → 1994)
# - Input validation and appropriate error handling
# - Edge cases and invalid inputs
#
# Roman Numeral Rules:
# --------------------
# Symbol | Value
# -------|------
#   I    |   1
#   V    |   5
#   X    |   10
#   L    |   50
#   C    |   100
#   D    |   500
#   M    |   1000
#
# Subtractive Notation Rules:
# - I can be placed before V (5) and X (10) to make 4 and 9
# - X can be placed before L (50) and C (100) to make 40 and 90
# - C can be placed before D (500) and M (1000) to make 400 and 900
#
# Valid Range: 1 to 3999
# - Romans did not have a symbol for zero
# - Standard notation doesn't exceed 3999 (MMMCMXCIX)
#
# Requirements:
# -------------
# 1. Implement a RomanNumeral class with the following interface:
#
#    RomanNumeral.to_roman(integer) → String
#      - Converts an integer to Roman numeral string
#      - Raises ArgumentError if input is invalid
#
#    RomanNumeral.to_integer(roman_string) → Integer
#      - Converts a Roman numeral string to integer
#      - Should be case-insensitive (accept "XIV" or "xiv")
#      - Raises ArgumentError if input is invalid
#
# 2. Input Validation:
#    - For to_roman: reject non-integers, values < 1, values > 3999
#    - For to_integer: reject invalid characters, malformed strings
#    - Invalid Roman numerals: "IIII", "VV", "LL", "DD", "MMMM", "IC", "XM", etc.
#
# 3. Error Messages:
#    - Clear, descriptive messages for each type of validation failure
#
# TDD Approach:
# -------------
# Follow strict red-green-refactor cycles:
#
# 1. Write ONE failing test (RED)
# 2. Write MINIMUM code to make it pass (GREEN)
# 3. Refactor while keeping tests green (REFACTOR)
# 4. Repeat
#
# Suggested Test Progression:
# ---------------------------
# Phase 1 - Basic Integer to Roman:
#   - Single symbols: 1→"I", 5→"V", 10→"X", 50→"L", 100→"C", 500→"D", 1000→"M"
#   - Additive cases: 2→"II", 3→"III", 6→"VI", 7→"VII", 15→"XV"
#   - Subtractive cases: 4→"IV", 9→"IX", 40→"XL", 90→"XC", 400→"CD", 900→"CM"
#   - Complex numbers: 1994→"MCMXCIV", 3999→"MMMCMXCIX", 444→"CDXLIV"
#
# Phase 2 - Roman to Integer:
#   - Single symbols: "I"→1, "V"→5, "X"→10, etc.
#   - Additive cases: "II"→2, "VI"→6, "XV"→15
#   - Subtractive cases: "IV"→4, "IX"→9, "XL"→40, "CM"→900
#   - Complex numbers: "MCMXCIV"→1994, "MMMCMXCIX"→3999
#   - Case insensitivity: "mcmxciv"→1994, "McM"→1900
#
# Phase 3 - Input Validation:
#   - Boundary cases: 0, -1, 4000, nil, ""
#   - Invalid Romans: "IIII", "VV", "IC", "XM", "abc", "I V"
#   - Type errors: 3.14, "123", [1,2,3], {a: 1}
#
# Phase 4 - Edge Cases:
#   - Whitespace handling: " XIV ", "\tX\n"
#   - Repeated conversion: to_integer(to_roman(n)) == n
#
# Implementation Hints:
# ---------------------
# - Consider using a lookup table for integer → Roman mappings
# - Include subtractive pairs (4, 9, 40, 90, 400, 900) in your mappings
# - For Roman → Integer, scan from left to right comparing adjacent symbols
# - When a smaller value appears before a larger value, subtract it
# - Build validation as a separate concern for clarity
#
# Example Usage:
# --------------
# RomanNumeral.to_roman(27)        # => "XXVII"
# RomanNumeral.to_roman(1994)      # => "MCMXCIV"
# RomanNumeral.to_integer("XLII")  # => 42
# RomanNumeral.to_integer("cdxliv") # => 444
# RomanNumeral.to_roman(0)         # => ArgumentError
# RomanNumeral.to_integer("IIII")  # => ArgumentError
#
# Time Expectation:
# -----------------
# - 45-60 minutes for complete TDD implementation
# - Focus on writing clean, well-organized tests
# - Practice narrating your thought process as you work
#
# ============================================================================

class RomanNumeral
  # Your implementation here
  # Remember: Write tests FIRST, then implement
end


# ============================================================================
# TEST SUITE (Example starter - expand as you TDD)
# ============================================================================
# Below is a minimal test structure to get you started.
# You should add MANY more test cases following the progression outlined above.
#
# Run tests with: ruby roman_numeral.rb

def assert_equal(expected, actual, message = nil)
  if expected == actual
    print "."
  else
    puts "\nFAILURE: #{message || 'Assertion failed'}"
    puts "  Expected: #{expected.inspect}"
    puts "  Actual:   #{actual.inspect}"
    exit 1
  end
end

def assert_raises(exception_class, message = nil)
  yield
  puts "\nFAILURE: #{message || "Expected #{exception_class} to be raised, but nothing was raised"}"
  exit 1
rescue exception_class
  print "."
rescue => e
  puts "\nFAILURE: #{message || "Expected #{exception_class}, got #{e.class}: #{e.message}"}"
  exit 1
end

# ============================================================================
# STARTER TESTS - Add more following TDD progression
# ============================================================================

puts "Running RomanNumeral tests..."

# Phase 1: Basic integer to Roman conversion
assert_equa3 "I", RomanNumeral.to_roman(1), "1 should convert to I"
assert_equal "V", RomanNumeral.to_roman(5), "5 should convert to V"
assert_equal "X", RomanNumeral.to_roman(10), "10 should convert to X"

# Add more tests here following the progression...
# TODO: Test additive cases (II, III, VI, etc.)
# TODO: Test subtractive cases (IV, IX, XL, etc.)
# TODO: Test complex numbers (1994, 3999, etc.)

# Phase 2: Roman to integer conversion
# TODO: Add tests for to_integer method

# Phase 3: Input validation
# TODO: Add validation tests

# Phase 4: Edge cases
# TODO: Add edge case tests

puts "\n✓ All tests passed!"
