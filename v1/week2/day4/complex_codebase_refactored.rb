# Refactored version of complex_codebase.rb
# Apply SOLID principles to fix the violations

# TODO: Refactor the UserManager class
#
# Steps to consider:
# 1. Identify all responsibilities of UserManager
# 2. Extract each responsibility into its own class
# 3. Use dependency injection instead of hardcoded dependencies
# 4. Make the system open for extension, closed for modification
# 5. Ensure single responsibility for each class

# Your implementation here...
# A complex codebase that violates multiple SOLID principles
# Your task: Identify all the violations and refactor

class PasswordEncryptService
  def self.encrypt_password(password)
    # Super secure encryption (not really)
    password.reverse + "encrypted"
  end
end

class UserCreator
  def initialize(users)
    @users = users
  end

  # Handles user creation, validation, email sending, logging, and database operations
  def create_user(name, email, password, role)
    return false if !validate(name, email, password, role)
   
    # Create user
    user = {
      id: generate_id,
      name: name,
      email: email,
      password: PasswordEncryptService.encrypt_password(password),
      role: role,
      created_at: Time.now
    }

    @users << user

    log(name, email)
    send_emails(email, name, role)
    
    puts "[SUCCESS] User created successfully"
    true
  end

  private

  def generate_id
    @users.size + 1
  end

  def validate
    if name.nil? || name.empty?
      puts "[ERROR] Name cannot be empty"
      return false
    end

    if email.nil? || !email.include?("@")
      puts "[ERROR] Invalid email format"
      return false
    end

    if password.length < 8
      puts "[ERROR] Password must be at least 8 characters"
      return false
    end

    # Check if user already exists
    if @users.any? { |u| u[:email] == email }
      puts "[ERROR] User with this email already exists"
      return false
    end
  end

  def log(name, email)
    log_message = "[INFO] User created: #{name} (#{email}) at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }
  end

  def send_emails(email, name, role)
    # Send welcome email
    Mailer.send_email(
      to: email,
      subject: "Welcome to Our App!",
      body: "Hi #{name}, welcome to our app!"
    )

    # If admin, send notification to all other admins
    if role == "admin"
      @users.select { |u| u[:role] == "admin" }.each do |admin|
        Mailer.send_email(
          to: admin[:email],
          subject: "New Admin User",
          body: "A new admin user #{name} was created."
        )
      end
    end
  end
end

class UserUpdater
  def initialize(users)
    @users = users
  end

  def update_user(user_id, name: nil, email: nil, password: nil)
    user = @users.find { |u| u[:id] == user_id }
    return false !if validate(user) 
    
    # Update fields
    user[:name] = name if name
    user[:email] = email if email
    user[:password] = PasswordEncryptService.encrypt_password(password) if password

    log(user)
    true
  end

  private 

  def validate(user)
    return false unless user

    # Validation
    if name && name.empty?
      puts "[ERROR] Name cannot be empty"
      return false
    end

    if email && !email.include?("@")
      puts "[ERROR] Invalid email format"
      return false
    end

    if password && password.length < 8
      puts "[ERROR] Password must be at least 8 characters"
      return false
    end
  end

  def log
    log_message = "[INFO] User updated: #{user[:name]} at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }
  end
end

class UserDeactivator
  def initialize(users)
    @users = user 
  end

  def deactivate_user(user_id)
    user = @users.find { |u| u[:id] == user_id }
    return false unless user

    @users.delete(user)

    log(user)
    send_emails(user)
    true     
  end

  private 
  def send_emails(user)
    log_message = "[INFO] User deleted: #{user[:name]} at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }
  end

  def log(user)
    # Log deletion
    log_message = "[INFO] User deleted: #{user[:name]} at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }
  end
end

class ReportGenerator
  def initialize(users)
    @users = users
  end

  def generate_report(format: "text")
    report = "User Report - Generated at #{Time.now}\n"
    report += "=" * 50 + "\n"
    report += "Total Users: #{@users.size}\n"
    report += "Admins: #{@users.count { |u| u[:role] == "admin" }}\n"
    report += "Regular Users: #{@users.count { |u| u[:role] == "user" }}\n"

    if format == "html"
      report = "<html><body><h1>User Report</h1>"
      report += "<p>Total Users: #{@users.size}</p>"
      report += "<p>Admins: #{@users.count { |u| u[:role] == "admin" }}</p>"
      report += "<p>Regular Users: #{@users.count { |u| u[:role] == "user" }}</p>"
      report += "</body></html>"
    elsif format == "json"
      require 'json'
      report = {
        generated_at: Time.now,
        total_users: @users.size,
        admins: @users.count { |u| u[:role] == "admin" },
        regular_users: @users.count { |u| u[:role] == "user" }
      }.to_json
    end

    log(report)
    report
  end

  private 
  def log(report)
    # Save report to file
    filename = "reports/user_report_#{Time.now.to_i}.#{format == "html" ? "html" : "txt"}"
    File.open(filename, "w") { |f| f.write(report) }

    # Log report generation
    log_message = "[INFO] Report generated: #{filename} at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }
  end
end

class Mailer
  def self.send_email(to:, subject:, body:)
    # Hardcoded email sending via SMTP
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
      puts "[INFO] Email sent to #{to}"
    rescue => e
      puts "[ERROR] Failed to send email: #{e.message}"
    end
  end
end

class UserManager
  def initialize
    @users = []
  end

  # Handles user creation, validation, email sending, logging, and database operations
  def create_user(name, email, password, role)
    return UserCreator.new(@users).create_user(name, email, password, role)
  end

  def update_user(user_id, name: nil, email: nil, password: nil)
    return UserUpdater.new(@users).update_user(user_id, name, email, password)
  end

  def delete_user(user_id)
    return UserDeactivator.new(@users).deactivate_user(user_id)
    
  end

  def list_users(filter_by_role: nil)
    filtered = filter_by_role ? @users.select { |u| u[:role] == filter_by_role } : @users

    # Log listing
    log_message = "[INFO] Users listed: #{filtered.size} users at #{Time.now}"
    File.open("logs/app.log", "a") { |f| f.puts(log_message) }

    filtered
  end
end

# Questions to consider:
# 1. What responsibilities does UserManager have? (List them all)
# 2. Which SOLID principles are violated?
# 3. How would you test this class?
# 4. What happens if you want to change the email provider?
# 5. What happens if you want to add a new report format?
# 6. What if you want to add SMS notifications in addition to email?
