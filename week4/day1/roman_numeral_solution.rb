# Solution file for Roman Numeral Converter
# This file will contain your TDD implementation

require "pry"
class RomanNumeral
  ROMAN_VALUES = {
    "M" => 1000,
    "CM" => 900,   # 900 - subtractive case
    "D" => 500,
    "CD" => 400,   # 400 - subtractive case
    "C" => 100,
    "XC" => 90,    # 90 - subtractive case
    "L" => 50,
    "XL" => 40,    # 40 - subtractive case
    "X" => 10,
    "IX" => 9,     # 9 - subtractive case
    "V" => 5,
    "IV" => 4,     # 4 - subtractive case
    "I" => 1
  }.freeze

  def self.to_roman(integer)
    roman = ""

    ROMAN_VALUES.each do |symbol, value|
      while integer >= value
        roman += symbol
        integer -= value
      end
    end

    roman
  end

  def self.to_integer(roman)
    SYMBOL_VALUES = {
      'M' => 1000, 'D' => 500, 'C' => 100, 'L' => 50,
      'X' => 10, 'V' => 5, 'I' => 1
    }

    integer_arr = []

    roman.chars.each do |roman_char|
      integer_arr << SYMBOL_VALUES[roman_char]
    end

    integer_arr.sum
  end
end

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

puts "Running RomanNumeral tests..."

# Phase 1: Basic integer to Roman conversion
assert_equal "I", RomanNumeral.to_roman(1), "1 should convert to I"
assert_equal "VI", RomanNumeral.to_roman(6), "6 should convert to VI"
assert_equal "X", RomanNumeral.to_roman(10), ""

assert_equal 1, RomanNumeral.to_integer("I"), ""
assert_equal 6, RomanNumeral.to_integer("VI"), ""