# Model Answer: Refactored Complex Codebase with SOLID Principles
# This demonstrates proper application of all five SOLID principles

# =============================================================================
# SINGLE RESPONSIBILITY PRINCIPLE (SRP)
# Each class has ONE reason to change
# =============================================================================

# Responsibility: Encrypt passwords
class PasswordEncryptor
  def encrypt(password)
    # Super secure encryption (not really)
    password.reverse + "encrypted"
  end
end

# Responsibility: Validate user data
class UserValidator
  def initialize(repository)
    @repository = repository
  end

  def validate(name:, email:, password:)
    errors = []

    errors << "Name cannot be empty" if name.nil? || name.empty?
    errors << "Invalid email format" if email.nil? || !email.include?("@")
    errors << "Password must be at least 8 characters" if password.length < 8
    errors << "User with this email already exists" if @repository.email_exists?(email)

    ValidationResult.new(errors)
  end

  def validate_update(name: nil, email: nil, password: nil)
    errors = []

    errors << "Name cannot be empty" if name && name.empty?
    errors << "Invalid email format" if email && !email.include?("@")
    errors << "Password must be at least 8 characters" if password && password.length < 8

    ValidationResult.new(errors)
  end
end

# Value object to hold validation results
class ValidationResult
  attr_reader :errors

  def initialize(errors = [])
    @errors = errors
  end

  def valid?
    @errors.empty?
  end

  def error_messages
    @errors.map { |e| "[ERROR] #{e}" }
  end
end

# Responsibility: Store and retrieve users
class UserRepository
  def initialize
    @users = []
  end

  def save(user)
    @users << user
  end

  def find(id)
    @users.find { |u| u[:id] == id }
  end

  def all
    @users
  end

  def filter_by_role(role)
    @users.select { |u| u[:role] == role }
  end

  def email_exists?(email)
    @users.any? { |u| u[:email] == email }
  end

  def delete(user)
    @users.delete(user)
  end

  def next_id
    @users.size + 1
  end

  def count
    @users.size
  end

  def count_by_role(role)
    @users.count { |u| u[:role] == role }
  end
end

# Responsibility: Log messages
class Logger
  def initialize(log_file = "logs/app.log")
    @log_file = log_file
  end

  def log(message)
    log_message = "[INFO] #{message} at #{Time.now}"
    File.open(@log_file, "a") { |f| f.puts(log_message) }
  end

  def error(message)
    log_message = "[ERROR] #{message} at #{Time.now}"
    File.open(@log_file, "a") { |f| f.puts(log_message) }
  end
end

# =============================================================================
# OPEN/CLOSED PRINCIPLE (OCP)
# Open for extension, closed for modification
# =============================================================================

# Notification Strategy Pattern - Easy to add new notification types
class NotificationStrategy
  def send(user, message_type, context = {})
    raise NotImplementedError, "Subclasses must implement send"
  end
end

class EmailNotificationStrategy < NotificationStrategy
  def initialize(mailer)
    @mailer = mailer
  end

  def send(user, message_type, context = {})
    case message_type
    when :welcome
      @mailer.send_email(
        to: user[:email],
        subject: "Welcome to Our App!",
        body: "Hi #{user[:name]}, welcome to our app!"
      )
    when :account_deleted
      @mailer.send_email(
        to: user[:email],
        subject: "Account Deleted",
        body: "Your account has been deleted. Sorry to see you go!"
      )
    when :new_admin
      @mailer.send_email(
        to: user[:email],
        subject: "New Admin User",
        body: "A new admin user #{context[:new_admin_name]} was created."
      )
    end
  end
end

# Easy to add SMS without modifying existing code
class SmsNotificationStrategy < NotificationStrategy
  def send(user, message_type, context = {})
    phone = user[:phone]
    return unless phone

    case message_type
    when :welcome
      send_sms(phone, "Welcome to our app, #{user[:name]}!")
    when :account_deleted
      send_sms(phone, "Your account has been deleted.")
    end
  end

  private

  def send_sms(phone, message)
    # SMS sending implementation
    puts "[INFO] SMS sent to #{phone}: #{message}"
  end
end

# Notification service that can use multiple strategies
class NotificationService
  def initialize(strategies = [])
    @strategies = strategies
  end

  def notify(user, message_type, context = {})
    @strategies.each do |strategy|
      strategy.send(user, message_type, context)
    end
  end

  def notify_multiple(users, message_type, context = {})
    users.each { |user| notify(user, message_type, context) }
  end
end

# Report Format Strategy Pattern - Easy to add new formats
class ReportFormatter
  def format(data)
    raise NotImplementedError, "Subclasses must implement format"
  end

  def file_extension
    raise NotImplementedError, "Subclasses must implement file_extension"
  end
end

class TextReportFormatter < ReportFormatter
  def format(data)
    report = "User Report - Generated at #{data[:generated_at]}\n"
    report += "=" * 50 + "\n"
    report += "Total Users: #{data[:total_users]}\n"
    report += "Admins: #{data[:admins]}\n"
    report += "Regular Users: #{data[:regular_users]}\n"
    report
  end

  def file_extension
    "txt"
  end
end

class HtmlReportFormatter < ReportFormatter
  def format(data)
    report = "<html><body><h1>User Report</h1>"
    report += "<p>Generated at: #{data[:generated_at]}</p>"
    report += "<p>Total Users: #{data[:total_users]}</p>"
    report += "<p>Admins: #{data[:admins]}</p>"
    report += "<p>Regular Users: #{data[:regular_users]}</p>"
    report += "</body></html>"
    report
  end

  def file_extension
    "html"
  end
end

class JsonReportFormatter < ReportFormatter
  def format(data)
    require 'json'
    data.to_json
  end

  def file_extension
    "json"
  end
end

# Easy to add CSV format without modifying existing code
class CsvReportFormatter < ReportFormatter
  def format(data)
    report = "Metric,Value\n"
    report += "Generated At,#{data[:generated_at]}\n"
    report += "Total Users,#{data[:total_users]}\n"
    report += "Admins,#{data[:admins]}\n"
    report += "Regular Users,#{data[:regular_users]}\n"
    report
  end

  def file_extension
    "csv"
  end
end

# =============================================================================
# LISKOV SUBSTITUTION PRINCIPLE (LSP)
# Subtypes must be substitutable for their base types
# =============================================================================

# Email sender interface
class EmailSender
  def send_email(to:, subject:, body:)
    raise NotImplementedError, "Subclasses must implement send_email"
  end
end

# SMTP implementation - can be substituted for EmailSender
class SmtpEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    require 'net/smtp'

    message = <<~MSG
      From: noreply@app.com
      To: #{to}
      Subject: #{subject}

      #{body}
    MSG

    begin
      Net::SMTP.start('smtp.gmail.com', 587) do |smtp|
        smtp.send_message(message, 'noreply@app.com', to)
      end
      puts "[INFO] Email sent to #{to} via SMTP"
    rescue => e
      puts "[ERROR] Failed to send email: #{e.message}"
    end
  end
end

# SendGrid implementation - can be substituted for EmailSender
class SendGridEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    # SendGrid API implementation
    puts "[INFO] Email sent to #{to} via SendGrid API"
    puts "  Subject: #{subject}"
    puts "  Body: #{body}"
  end
end

# Console implementation for testing - can be substituted for EmailSender
class ConsoleEmailSender < EmailSender
  def send_email(to:, subject:, body:)
    puts "[CONSOLE EMAIL]"
    puts "To: #{to}"
    puts "Subject: #{subject}"
    puts "Body: #{body}"
    puts "=" * 50
  end
end

# =============================================================================
# INTERFACE SEGREGATION PRINCIPLE (ISP)
# Clients should not depend on interfaces they don't use
# =============================================================================

# Instead of one large interface, split into focused ones

# Interface for user CRUD operations
class UserService
  def initialize(repository:, validator:, encryptor:, logger:, notifier:)
    @repository = repository
    @validator = validator
    @encryptor = encryptor
    @logger = logger
    @notifier = notifier
  end

  def create_user(name:, email:, password:, role:)
    validation = @validator.validate(name: name, email: email, password: password)

    unless validation.valid?
      validation.error_messages.each { |msg| puts msg }
      return false
    end

    user = {
      id: @repository.next_id,
      name: name,
      email: email,
      password: @encryptor.encrypt(password),
      role: role,
      created_at: Time.now
    }

    @repository.save(user)
    @logger.log("User created: #{name} (#{email})")
    @notifier.notify(user, :welcome)

    # Notify other admins if new user is admin
    if role == "admin"
      admins = @repository.filter_by_role("admin").reject { |u| u[:id] == user[:id] }
      @notifier.notify_multiple(admins, :new_admin, { new_admin_name: name })
    end

    puts "[SUCCESS] User created successfully"
    true
  end

  def update_user(id:, name: nil, email: nil, password: nil)
    user = @repository.find(id)
    unless user
      puts "[ERROR] User not found"
      return false
    end

    validation = @validator.validate_update(name: name, email: email, password: password)

    unless validation.valid?
      validation.error_messages.each { |msg| puts msg }
      return false
    end

    user[:name] = name if name
    user[:email] = email if email
    user[:password] = @encryptor.encrypt(password) if password

    @logger.log("User updated: #{user[:name]}")
    puts "[SUCCESS] User updated successfully"
    true
  end

  def delete_user(id:)
    user = @repository.find(id)
    unless user
      puts "[ERROR] User not found"
      return false
    end

    @repository.delete(user)
    @logger.log("User deleted: #{user[:name]}")
    @notifier.notify(user, :account_deleted)

    puts "[SUCCESS] User deleted successfully"
    true
  end
end

# Interface for user queries (read-only)
class UserQueryService
  def initialize(repository:, logger:)
    @repository = repository
    @logger = logger
  end

  def list_users(filter_by_role: nil)
    users = filter_by_role ? @repository.filter_by_role(filter_by_role) : @repository.all
    @logger.log("Users listed: #{users.size} users")
    users
  end

  def find_user(id:)
    @repository.find(id)
  end
end

# Interface for reporting (separate from user management)
class ReportService
  def initialize(repository:, logger:)
    @repository = repository
    @logger = logger
  end

  def generate_report(formatter:)
    data = {
      generated_at: Time.now,
      total_users: @repository.count,
      admins: @repository.count_by_role("admin"),
      regular_users: @repository.count_by_role("user")
    }

    report = formatter.format(data)

    # Save report to file
    filename = "reports/user_report_#{Time.now.to_i}.#{formatter.file_extension}"
    File.open(filename, "w") { |f| f.write(report) }

    @logger.log("Report generated: #{filename}")

    report
  end
end

# =============================================================================
# DEPENDENCY INVERSION PRINCIPLE (DIP)
# Depend on abstractions, not concretions
# =============================================================================

# High-level UserManager depends on abstractions (injected dependencies)
# Not on concrete implementations (File, Net::SMTP, etc.)
class UserManager
  def initialize(user_service:, query_service:, report_service:)
    @user_service = user_service
    @query_service = query_service
    @report_service = report_service
  end

  # Delegate to specialized services
  def create_user(name:, email:, password:, role:)
    @user_service.create_user(name: name, email: email, password: password, role: role)
  end

  def update_user(id:, name: nil, email: nil, password: nil)
    @user_service.update_user(id: id, name: name, email: email, password: password)
  end

  def delete_user(id:)
    @user_service.delete_user(id: id)
  end

  def list_users(filter_by_role: nil)
    @query_service.list_users(filter_by_role: filter_by_role)
  end

  def generate_report(format: "text")
    formatter = case format
                when "html" then HtmlReportFormatter.new
                when "json" then JsonReportFormatter.new
                when "csv" then CsvReportFormatter.new
                else TextReportFormatter.new
                end

    @report_service.generate_report(formatter: formatter)
  end
end

# =============================================================================
# DEPENDENCY INJECTION & COMPOSITION ROOT
# All dependencies are wired up here
# =============================================================================

def create_user_manager(email_sender_type: :console)
  # Choose email implementation (LSP - all are interchangeable)
  email_sender = case email_sender_type
                 when :smtp then SmtpEmailSender.new
                 when :sendgrid then SendGridEmailSender.new
                 else ConsoleEmailSender.new
                 end

  # Create dependencies
  repository = UserRepository.new
  logger = Logger.new("logs/app.log")
  encryptor = PasswordEncryptor.new
  validator = UserValidator.new(repository)

  # Create notification strategies (OCP - easy to add more)
  email_strategy = EmailNotificationStrategy.new(email_sender)
  sms_strategy = SmsNotificationStrategy.new
  notifier = NotificationService.new([email_strategy, sms_strategy])

  # Create services (ISP - focused interfaces)
  user_service = UserService.new(
    repository: repository,
    validator: validator,
    encryptor: encryptor,
    logger: logger,
    notifier: notifier
  )

  query_service = UserQueryService.new(
    repository: repository,
    logger: logger
  )

  report_service = ReportService.new(
    repository: repository,
    logger: logger
  )

  # Create manager (DIP - depends on abstractions)
  UserManager.new(
    user_service: user_service,
    query_service: query_service,
    report_service: report_service
  )
end

# =============================================================================
# DEMONSTRATION
# =============================================================================

if __FILE__ == $0
  puts "=" * 80
  puts "SOLID PRINCIPLES DEMONSTRATION"
  puts "=" * 80
  puts

  # Create user manager with console email (for testing)
  manager = create_user_manager(email_sender_type: :console)

  puts "1. Creating users..."
  puts "-" * 40
  manager.create_user(name: "Alice", email: "alice@example.com", password: "password123", role: "admin")
  manager.create_user(name: "Bob", email: "bob@example.com", password: "password456", role: "user")
  manager.create_user(name: "Charlie", email: "charlie@example.com", password: "password789", role: "admin")
  puts

  puts "2. Listing all users..."
  puts "-" * 40
  users = manager.list_users
  users.each { |u| puts "  - #{u[:name]} (#{u[:email]}) - #{u[:role]}" }
  puts

  puts "3. Listing admins only..."
  puts "-" * 40
  admins = manager.list_users(filter_by_role: "admin")
  admins.each { |u| puts "  - #{u[:name]} (#{u[:email]})" }
  puts

  puts "4. Generating reports in different formats..."
  puts "-" * 40

  puts "\nText Report:"
  text_report = manager.generate_report(format: "text")
  puts text_report

  puts "\nHTML Report:"
  html_report = manager.generate_report(format: "html")
  puts html_report[0..200] + "..."

  puts "\nJSON Report:"
  json_report = manager.generate_report(format: "json")
  puts json_report

  puts "\nCSV Report:"
  csv_report = manager.generate_report(format: "csv")
  puts csv_report
  puts

  puts "5. Updating a user..."
  puts "-" * 40
  manager.update_user(id: 1, name: "Alice Smith")
  puts

  puts "6. Deleting a user..."
  puts "-" * 40
  manager.delete_user(id: 2)
  puts

  puts "7. Final user list..."
  puts "-" * 40
  users = manager.list_users
  users.each { |u| puts "  - #{u[:name]} (#{u[:email]}) - #{u[:role]}" }
  puts

  puts "=" * 80
  puts "BENEFITS OF THIS DESIGN"
  puts "=" * 80
  puts "✓ SRP: Each class has one reason to change"
  puts "✓ OCP: Easy to add new notification types or report formats"
  puts "✓ LSP: Email senders are interchangeable"
  puts "✓ ISP: Services have focused interfaces"
  puts "✓ DIP: High-level code depends on abstractions"
  puts
  puts "To change email provider: Just pass different sender to create_user_manager"
  puts "To add SMS: Already implemented! Just add to notification strategies"
  puts "To add new report format: Create new formatter class (no existing code changes)"
  puts "=" * 80
end
