# Week 3, Day 3: Factory Pattern
# Challenge: Parser Factory

# Problem:
# Create a parser factory that returns the right parser (JSON, XML, CSV)
# based on file extension. The factory should be extensible and follow
# the Open/Closed Principle.

# Requirements:
# 1. Implement a ParserFactory that creates the appropriate parser based on file extension
# 2. Create parser classes for JSON, XML, and CSV formats
# 3. Each parser should have a #parse method that takes file content as a string
# 4. The factory should be extensible (easy to add new parser types without modifying existing code)
# 5. Handle unknown file types gracefully

# Example Usage:
#
# parser = ParserFactory.create_parser("data.json")
# result = parser.parse('{"name": "John", "age": 30}')
# # => {:name => "John", :age => 30}
#
# parser = ParserFactory.create_parser("users.csv")
# result = parser.parse("name,age\nJohn,30\nJane,25")
# # => [{:name => "John", :age => "30"}, {:name => "Jane", :age => "25"}]

# Instructions:
# 1. Design your class hierarchy - consider what should be in a base Parser class
# 2. Implement the factory pattern - how will it determine which parser to create?
# 3. Think about error handling - what happens with unknown extensions?
# 4. Consider how to register new parsers without modifying the factory code
# 5. Test your implementation with the example usage above

# Bonus Challenges:
# - Implement a registration mechanism where new parsers can register themselves
# - Add support for parsing from files (not just strings)
# - Implement a Parser decorator that adds caching
# - Add logging to track which parser is being used

# Write your solution below:
