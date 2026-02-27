# Week 2, Day 4: Composition vs Inheritance + SOLID Review

## Topic
Composition vs Inheritance + SOLID Review

## Exercise
Given a `Vehicle` inheritance hierarchy that's gotten messy, refactor to composition. Apply multiple SOLID principles to a complex codebase.

## Learning Objectives
- Understand when inheritance becomes problematic
- Know how to refactor inheritance to composition
- Apply multiple SOLID principles in combination
- Recognize the "favor composition over inheritance" principle

## Problems to Solve

### Part 1: Vehicle Hierarchy Refactoring (45-60 min)
Review `vehicle_inheritance_before.rb` - a messy inheritance hierarchy with problems like:
- Deep inheritance chains
- Duplicated code
- Rigid structure that's hard to extend
- Violations of Liskov Substitution Principle

Refactor to composition-based design in `vehicle_composition_after.rb`

### Part 2: SOLID Review Exercise (30-45 min)
Review `complex_codebase.rb` which violates multiple SOLID principles.
Identify and fix:
- Single Responsibility violations
- Open/Closed violations
- Dependency issues
- Interface segregation problems

## Key Questions to Consider
1. When is inheritance appropriate vs composition?
2. How do you identify code that needs composition?
3. How do multiple SOLID principles work together?
4. What are the tradeoffs of composition vs inheritance?

## Expected Deliverables
1. `vehicle_composition_after.rb` - refactored vehicle system
2. `complex_codebase_refactored.rb` - fixed SOLID violations
3. Notes on your refactoring decisions and tradeoffs
