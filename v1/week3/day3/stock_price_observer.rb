# Week 3, Day 3: Observer Pattern
# Challenge: Stock Price Alerting System

# Problem:
# Build a stock price monitoring system where multiple observers (watchers)
# get notified when a stock price changes. Different watchers may care about
# different conditions (price drops, price increases, specific thresholds, etc.)

# Requirements:
# 1. Implement a Stock class that maintains a current price and notifies observers when it changes
# 2. Implement multiple observer classes with different alert strategies:
#    - PriceDropAlert: Notifies when price drops by a certain percentage
#    - PriceIncreaseAlert: Notifies when price increases by a certain percentage
#    - Logger: Logs all price changes
# 3. Observers should be able to subscribe and unsubscribe from stocks
# 4. When a stock price changes, all subscribed observers should be notified
# 5. Each observer can react differently to the notification

# Example Usage:
#
# stock = Stock.new("AAPL", 150.00)
#
# drop_alert = PriceDropAlert.new(threshold_percent: 5)
# increase_alert = PriceIncreaseAlert.new(threshold_percent: 3)
# logger = PriceLogger.new
#
# stock.attach(drop_alert)
# stock.attach(increase_alert)
# stock.attach(logger)
#
# stock.price = 155.00
# # Logger prints: "AAPL price changed from $150.00 to $155.00"
# # IncreaseAlert prints: "Alert! AAPL increased by 3.33%"
#
# stock.price = 142.50
# # Logger prints: "AAPL price changed from $155.00 to $142.50"
# # PriceDropAlert prints: "Alert! AAPL dropped by 8.06%"
#
# stock.detach(drop_alert)
# stock.price = 130.00

# Instructions:
# 1. Implement the Observable pattern in the Stock class (attach, detach, notify)
# 2. Create a base Observer interface or abstract class
# 3. Implement each specific observer type with its own update logic
# 4. Think about what data observers need when they're notified
# 5. Consider edge cases (what if price doesn't change? what if there are no observers?)

# Bonus Challenges:
# - Add a Portfolio class that can observe multiple stocks
# - Implement a CompositeAlert that triggers when multiple conditions are met
# - Add support for observer priorities (some observers get notified first)
# - Implement an alert history/audit trail
# - Add email/SMS notification capabilities (simulated)

# Write your solution below:
