# SOLID Principles - Comprehensive Guide

## Overview

This guide explains how the model answer (`complex_codebase_model_answer.rb`) properly implements all five SOLID principles to transform the messy original codebase into a maintainable, extensible architecture.

---

## Table of Contents
1. [Single Responsibility Principle (SRP)](#1-single-responsibility-principle-srp)
2. [Open/Closed Principle (OCP)](#2-openclosed-principle-ocp)
3. [Liskov Substitution Principle (LSP)](#3-liskov-substitution-principle-lsp)
4. [Interface Segregation Principle (ISP)](#4-interface-segregation-principle-isp)
5. [Dependency Inversion Principle (DIP)](#5-dependency-inversion-principle-dip)
6. [Comparison: Before vs After](#comparison-before-vs-after)
7. [Key Takeaways](#key-takeaways)

---

## 1. Single Responsibility Principle (SRP)

**Definition:** A class should have only ONE reason to change.

### Problem in Original Code
The `UserManager` class had **7 different responsibilities**:
- User creation
- User validation
- Password encryption
- Email sending
- File logging
- Report generation
- User storage

### Solution in Model Answer

Each responsibility is extracted into its own class:

```ruby
# Responsibility: Encrypt passwords
class PasswordEncryptor
  def encrypt(password)
    password.reverse + "encrypted"
  end
end

# Responsibility: Validate user data
class UserValidator
  def validate(name:, email:, password:)
    # Only validates, doesn't create or store
  end
end

# Responsibility: Store and retrieve users
class UserRepository
  def save(user)
    @users << user
  end

  def find(id)
    @users.find { |u| u[:id] == id }
  end
  # ... only data access methods
end

# Responsibility: Log messages
class Logger
  def log(message)
    File.open(@log_file, "a") { |f| f.puts(log_message) }
  end
end
```

### Benefits
- **Easy to test:** Each class can be tested independently
- **Easy to maintain:** Changing validation logic doesn't affect logging
- **Easy to reuse:** `Logger` can be used anywhere in the application
- **Clear purpose:** Each class name tells you exactly what it does

### Real-World Example
Think of a restaurant:
- ❌ **Bad:** One person cooks, serves, cleans, manages inventory, handles payment
- ✅ **Good:** Chef cooks, waiter serves, cleaner cleans, manager handles inventory, cashier handles payment

---

## 2. Open/Closed Principle (OCP)

**Definition:** Software entities should be **open for extension** but **closed for modification**.

### Problem in Original Code

Adding a new report format required modifying the `generate_report` method:

```ruby
# Original code - VIOLATES OCP
def generate_report(format: "text")
  if format == "html"
    # HTML generation
  elsif format == "json"
    # JSON generation
  # To add CSV, you must MODIFY this method
  elsif format == "csv"  # ❌ Modification required!
    # CSV generation
  end
end
```

### Solution in Model Answer

Use the **Strategy Pattern** to allow extension without modification:

```ruby
# Base class (abstraction)
class ReportFormatter
  def format(data)
    raise NotImplementedError
  end

  def file_extension
    raise NotImplementedError
  end
end

# Concrete implementations
class TextReportFormatter < ReportFormatter
  def format(data)
    "User Report - Generated at #{data[:generated_at]}\n..."
  end

  def file_extension
    "txt"
  end
end

class HtmlReportFormatter < ReportFormatter
  def format(data)
    "<html><body><h1>User Report</h1>..."
  end

  def file_extension
    "html"
  end
end

# Easy to add CSV without modifying existing code! ✅
class CsvReportFormatter < ReportFormatter
  def format(data)
    "Metric,Value\nGenerated At,#{data[:generated_at]}\n..."
  end

  def file_extension
    "csv"
  end
end

# Usage
class ReportService
  def generate_report(formatter:)
    data = collect_data
    report = formatter.format(data)  # Polymorphism!
    save_to_file(report, formatter.file_extension)
  end
end
```

### Benefits
- **Add new formats easily:** Create new class, don't touch existing code
- **No risk of breaking existing features:** Old formatters unchanged
- **Testable:** Each formatter tested independently

### Another Example: Notifications

```ruby
# Base strategy
class NotificationStrategy
  def send(user, message_type, context = {})
    raise NotImplementedError
  end
end

# Email notifications
class EmailNotificationStrategy < NotificationStrategy
  def send(user, message_type, context = {})
    @mailer.send_email(to: user[:email], ...)
  end
end

# SMS notifications - NEW! No modification to existing code ✅
class SmsNotificationStrategy < NotificationStrategy
  def send(user, message_type, context = {})
    send_sms(user[:phone], ...)
  end
end

# Push notifications - NEW! No modification to existing code ✅
class PushNotificationStrategy < NotificationStrategy
  def send(user, message_type, context = {})
    send_push(user[:device_token], ...)
  end
end

# Service uses all strategies
class NotificationService
  def initialize(strategies = [])
    @strategies = strategies  # Can add any number of strategies!
  end

  def notify(user, message_type, context = {})
    @strategies.each { |strategy| strategy.send(user, message_type, context) }
  end
end
```

### Real-World Example
Think of electrical outlets:
- ❌ **Bad:** Hardwire every device directly to the wall (modify wall for new device)
- ✅ **Good:** Standard outlet interface; plug in any device (extend with new devices)

---

## 3. Liskov Substitution Principle (LSP)

**Definition:** Subtypes must be substitutable for their base types without breaking the program.

### Problem in Original Code

The `Mailer` class was hardcoded to SMTP:

```ruby
class Mailer
  def self.send_email(to:, subject:, body:)
    # Hardcoded to SMTP - can't substitute!
    Net::SMTP.start('smtp.gmail.com', 587) do |smtp|
      smtp.send_message(message, 'noreply@app.com', to)
    end
  end
end
```

### Solution in Model Answer

Create an abstract base class and multiple interchangeable implementations:

```ruby
# Base class (contract)
class EmailSender
  def send_email(to:, subject:, body:)
    raise NotImplementedError
  end
end

# SMTP implementation
class SmtpEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    Net::SMTP.start('smtp.gmail.com', 587) do |smtp|
      smtp.send_message(message, 'noreply@app.com', to)
    end
  end
end

# SendGrid implementation - can substitute for SmtpEmailSender! ✅
class SendGridEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    # SendGrid API call
    SendGrid::API.send(to: to, subject: subject, body: body)
  end
end

# Console implementation (for testing) - can substitute too! ✅
class ConsoleEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    puts "[CONSOLE EMAIL] To: #{to}, Subject: #{subject}"
  end
end
```

### Usage - All are interchangeable!

```ruby
# Production: Use SMTP
email_sender = SmtpEmailSender.new
notification = EmailNotificationStrategy.new(email_sender)

# Production: Switch to SendGrid (no code changes needed!)
email_sender = SendGridEmailSender.new
notification = EmailNotificationStrategy.new(email_sender)

# Testing: Use console (no code changes needed!)
email_sender = ConsoleEmailSender.new
notification = EmailNotificationStrategy.new(email_sender)

# The notification code doesn't care which implementation!
notification.send(user, :welcome)  # Works with all three!
```

### The LSP Contract

All `EmailSender` implementations must:
1. Accept the same parameters (`to:`, `subject:`, `body:`)
2. Return the same type (implicit void in Ruby)
3. Not throw unexpected exceptions
4. Maintain the same behavior contract (send email)

### Benefits
- **Easy to test:** Use `ConsoleEmailSender` in tests
- **Easy to switch providers:** Change one line in config
- **No vendor lock-in:** Not tied to specific email service

### Real-World Example
Think of car keys:
- ❌ **Bad:** Each car requires a completely different mechanism to start
- ✅ **Good:** All cars use the same "turn key" or "press button" interface (substitutable)

---

## 4. Interface Segregation Principle (ISP)

**Definition:** Clients should not be forced to depend on interfaces they don't use.

### Problem in Original Code

`UserManager` forced clients to depend on ALL methods even if they only needed one:

```ruby
class UserManager
  def create_user(...) end
  def update_user(...) end
  def delete_user(...) end
  def list_users(...) end
  def generate_report(...) end  # ❌ Why does a "UserManager" generate reports?
end

# Client only wants to read users, but depends on everything!
class UserDisplayComponent
  def initialize(user_manager)
    @user_manager = user_manager  # Has access to delete_user, create_user, etc.
  end

  def show_users
    @user_manager.list_users  # Only needs this method!
  end
end
```

### Solution in Model Answer

Split into **focused interfaces**:

```ruby
# Interface 1: User CRUD operations
class UserService
  def create_user(name:, email:, password:, role:) end
  def update_user(id:, name:, email:, password:) end
  def delete_user(id:) end
end

# Interface 2: User queries (read-only)
class UserQueryService
  def list_users(filter_by_role: nil) end
  def find_user(id:) end
end

# Interface 3: Reporting (separate concern)
class ReportService
  def generate_report(formatter:) end
end

# Now clients only depend on what they need!
class UserDisplayComponent
  def initialize(query_service)
    @query_service = query_service  # Only read operations!
  end

  def show_users
    @query_service.list_users
  end
end

class UserAdminPanel
  def initialize(user_service, query_service)
    @user_service = user_service    # Write operations
    @query_service = query_service  # Read operations
  end
end

class ReportingDashboard
  def initialize(report_service)
    @report_service = report_service  # Only reporting!
  end
end
```

### Benefits
- **Principle of least privilege:** Components only access what they need
- **Easier to understand:** Clear what each service does
- **Easier to test:** Mock only the methods you use
- **Better security:** Read-only components can't accidentally modify data

### Real-World Example
Think of user permissions:
- ❌ **Bad:** All employees have admin access to everything
- ✅ **Good:** Cashiers access POS system, managers access reports, admins access settings

---

## 5. Dependency Inversion Principle (DIP)

**Definition:**
- High-level modules should not depend on low-level modules
- Both should depend on abstractions
- Abstractions should not depend on details

### Problem in Original Code

`UserManager` directly depended on concrete implementations:

```ruby
class UserManager
  def create_user(name, email, password, role)
    # Direct dependency on File ❌
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }

    # Direct dependency on password encryption logic ❌
    password.reverse + "encrypted"

    # Direct dependency on Net::SMTP ❌
    Net::SMTP.start('smtp.gmail.com', 587) do |smtp|
      smtp.send_message(message, 'noreply@app.com', to)
    end
  end
end
```

**Problems:**
- Can't test without creating real files
- Can't test without sending real emails
- Can't swap email providers
- Tightly coupled to infrastructure

### Solution in Model Answer

**Depend on abstractions (injected dependencies):**

```ruby
class UserService
  # Depend on abstractions (interfaces), not concretions ✅
  def initialize(repository:, validator:, encryptor:, logger:, notifier:)
    @repository = repository  # Abstract: could be InMemory, Database, API
    @validator = validator    # Abstract: validation strategy
    @encryptor = encryptor    # Abstract: encryption strategy
    @logger = logger          # Abstract: logging strategy
    @notifier = notifier      # Abstract: notification strategy
  end

  def create_user(name:, email:, password:, role:)
    # Use abstractions - don't care about implementation!
    validation = @validator.validate(name: name, email: email, password: password)
    return false unless validation.valid?

    user = build_user(name, email, @encryptor.encrypt(password), role)
    @repository.save(user)
    @logger.log("User created: #{name}")
    @notifier.notify(user, :welcome)
  end
end
```

### Dependency Injection (Composition Root)

All dependencies are created and wired up in ONE place:

```ruby
def create_user_manager(email_sender_type: :console)
  # Create all dependencies
  email_sender = case email_sender_type
                 when :smtp then SmtpEmailSender.new
                 when :sendgrid then SendGridEmailSender.new
                 else ConsoleEmailSender.new
                 end

  repository = UserRepository.new
  logger = Logger.new("logs/app.log")
  encryptor = PasswordEncryptor.new
  validator = UserValidator.new(repository)

  email_strategy = EmailNotificationStrategy.new(email_sender)
  sms_strategy = SmsNotificationStrategy.new
  notifier = NotificationService.new([email_strategy, sms_strategy])

  # Inject dependencies
  user_service = UserService.new(
    repository: repository,
    validator: validator,
    encryptor: encryptor,
    logger: logger,
    notifier: notifier
  )

  query_service = UserQueryService.new(repository: repository, logger: logger)
  report_service = ReportService.new(repository: repository, logger: logger)

  UserManager.new(
    user_service: user_service,
    query_service: query_service,
    report_service: report_service
  )
end

# Usage - all configuration in one place!
manager = create_user_manager(email_sender_type: :smtp)     # Production
manager = create_user_manager(email_sender_type: :console)  # Testing
```

### Benefits of DIP

1. **Testability:**
```ruby
# Easy to test with mock dependencies
mock_repository = MockRepository.new
mock_logger = MockLogger.new
mock_encryptor = MockEncryptor.new
mock_validator = MockValidator.new
mock_notifier = MockNotifier.new

service = UserService.new(
  repository: mock_repository,
  validator: mock_validator,
  encryptor: mock_encryptor,
  logger: mock_logger,
  notifier: mock_notifier
)

# Test without real files, emails, or database!
service.create_user(name: "Test", email: "test@test.com", ...)
assert mock_logger.received?("User created: Test")
```

2. **Flexibility:**
```ruby
# Switch from file logging to database logging
logger = DatabaseLogger.new  # Instead of Logger.new

# Switch from in-memory to database storage
repository = DatabaseRepository.new  # Instead of UserRepository.new

# Add multiple notification channels
notifier = NotificationService.new([
  EmailNotificationStrategy.new(email_sender),
  SmsNotificationStrategy.new,
  PushNotificationStrategy.new,
  SlackNotificationStrategy.new
])
```

3. **No vendor lock-in:**
- Not tied to specific email provider
- Not tied to specific database
- Not tied to specific logging service

### Real-World Example
Think of power tools:
- ❌ **Bad:** Drill with hardwired plug (depends on specific outlet type)
- ✅ **Good:** Drill with battery interface (depends on abstraction, any battery works)

---

## Comparison: Before vs After

### Original Code Problems

```ruby
class UserManager
  def create_user(name, email, password, role)
    # SRP violation: 7 responsibilities in one class
    # - Validation
    # - User creation
    # - Password encryption
    # - Data storage
    # - File logging
    # - Email sending
    # - Business logic (admin notifications)

    # DIP violation: Direct dependencies
    if name.nil? || name.empty?  # ❌ Validation logic mixed in
      puts "[ERROR] Name cannot be empty"
      return false
    end

    password.reverse + "encrypted"  # ❌ Hardcoded encryption

    File.open("logs/app.log", "a") { |f| f.puts(log_message) }  # ❌ Hardcoded file I/O

    Net::SMTP.start('smtp.gmail.com', 587) do |smtp|  # ❌ Hardcoded email provider
      smtp.send_message(message, 'noreply@app.com', to)
    end
  end

  def generate_report(format: "text")
    # OCP violation: Must modify to add formats
    if format == "html"
      # HTML code
    elsif format == "json"
      # JSON code
    # Must modify this method to add CSV ❌
    end
  end
end
```

**Consequences:**
- Hard to test (requires real files, SMTP server)
- Hard to extend (must modify existing code)
- Hard to maintain (change one thing, risk breaking another)
- Hard to reuse (can't use just validation elsewhere)
- Vendor lock-in (tied to SMTP)

### Refactored Code Benefits

```ruby
# SRP: Each class has one responsibility
class PasswordEncryptor
  def encrypt(password) ... end
end

class UserValidator
  def validate(name:, email:, password:) ... end
end

class Logger
  def log(message) ... end
end

# OCP: Can extend without modification
class CsvReportFormatter < ReportFormatter
  def format(data) ... end  # Just add this class!
end

class SmsNotificationStrategy < NotificationStrategy
  def send(user, message_type, context) ... end  # Just add this class!
end

# LSP: Interchangeable implementations
class SmtpEmailSender < EmailSender ... end
class SendGridEmailSender < EmailSender ... end
class ConsoleEmailSender < EmailSender ... end

# ISP: Focused interfaces
class UserService          # Write operations
class UserQueryService     # Read operations
class ReportService        # Reporting

# DIP: Depend on abstractions
class UserService
  def initialize(repository:, validator:, encryptor:, logger:, notifier:)
    # All dependencies injected! ✅
  end
end
```

**Benefits:**
- Easy to test (inject mocks)
- Easy to extend (add new classes)
- Easy to maintain (isolated changes)
- Easy to reuse (each class is independent)
- No vendor lock-in (swap implementations)

---

## Key Takeaways

### 1. SRP (Single Responsibility)
**Remember:** "One class, one job"
- If a class name has "and" in its description, split it
- If you can't name a class easily, it's doing too much

### 2. OCP (Open/Closed)
**Remember:** "Add features by adding code, not changing code"
- Use inheritance/polymorphism for variations
- Use Strategy pattern for algorithms
- Use Template Method for procedures

### 3. LSP (Liskov Substitution)
**Remember:** "Subtypes should work anywhere the parent works"
- Keep the same interface
- Don't add extra requirements
- Don't weaken guarantees

### 4. ISP (Interface Segregation)
**Remember:** "Many small interfaces > one large interface"
- Clients should only see what they need
- Split fat interfaces into focused ones
- Principle of least privilege

### 5. DIP (Dependency Inversion)
**Remember:** "Depend on abstractions, not concretions"
- Inject dependencies via constructor
- Use interfaces/base classes
- Configure dependencies at composition root

### The SOLID Checklist

When writing code, ask:
- [ ] Does each class have one clear responsibility? (SRP)
- [ ] Can I add features without modifying existing code? (OCP)
- [ ] Are my subclasses truly substitutable? (LSP)
- [ ] Are my interfaces focused and minimal? (ISP)
- [ ] Am I depending on abstractions, not implementations? (DIP)

### Common Mistakes to Avoid

1. **Over-engineering:** Don't add abstraction until you need it
2. **Wrong abstractions:** Make sure your interfaces make sense
3. **Leaky abstractions:** Don't expose implementation details
4. **Premature optimization:** Solve the problem first, then refactor

### When to Apply SOLID

- ✅ **Do apply when:**
  - Building systems that will change
  - Working in a team
  - Code will be maintained long-term
  - Need to test independently

- ❌ **Don't over-apply when:**
  - Writing throwaway scripts
  - Prototyping
  - Requirements are crystal clear and won't change
  - Code is extremely simple

---

## Practice Exercises

1. **Identify violations:** Review your own code for SOLID violations
2. **Refactor gradually:** Pick one principle at a time
3. **Write tests:** Verify behavior doesn't change
4. **Get feedback:** Have others review your refactoring

## Further Reading

- "Clean Code" by Robert C. Martin
- "Design Patterns: Elements of Reusable Object-Oriented Software"
- "Refactoring: Improving the Design of Existing Code" by Martin Fowler

---

**Remember:** SOLID principles are guidelines, not rules. Use judgment. The goal is **maintainable, flexible, testable code** - not perfect adherence to principles.
