# Refactor the vehicle hierarchy using composition
# Goals:
# - Replace inheritance with composition
# - Make it easy to add new vehicle types
# - Follow SOLID principles
# - Remove LSP violations
# - Make the system flexible and extensible

# TODO: Implement your composition-based vehicle system here
#
# Hints:
# - Think about what capabilities/behaviors a vehicle can have
# - Create separate classes or modules for each capability
# - Compose vehicles from these capabilities
# - Consider using dependency injection
# - Think about how to handle vehicles with multiple capabilities

# Your implementation here...

require "pry"

class DriveBehavior
  def move
    "Driving on land"
  end
end

class SailBehavior
  def sail 
    "Sailing on water"
  end
end

class CarHorn
  def honk
    "Beep beep!"
  end
end

class BicycleBell
  def honk 
   "Ring ring!"
  end 
end

class Car
  def initialize(color:, make:, model:, moving_behavior:, honk_source:)
    @color = color
    @make = make
    @model = model
    @moving_behavior = moving_behavior
    @honk_source = honk_source
  end

  attr_reader :color, :make, :model

  def drive
    @moving_behavior.move
  end

  def honk
    return @honk_source.nil?
    @honk_source.honk
  end

  def start_engine
    "Engine started"
  end

  def stop_engine
    "Engine stopped"
  end
end

class Bicycle
  def initialize(color, brand, type, honk_source)
    @honk_source = honk_source
  end

  def honk
    @honk_source.honk
  end
end



# Example usage that shows the problems:
if __FILE__ == $0

  drive = DriveBehavior.new
  sail = SailBehavior.new
  car_horn_honk = CarHorn.new
  bicycle_bell = BicycleBell.new
  
  car = Car.new(color: "red", make: "Toyota", model: "Camry", moving_behavior: drive, honk_source: car_horn_honk)
  puts car.start_engine
  puts car.drive
  puts car.honk

  bike = Bicycle.new("blue", "Trek", "Mountain", bicycle_bell)
  begin
    puts bike.start_engine # This raises an error - LSP violation!
  rescue => e
    puts "Error: #{e.message}"
  end

  # boat = Boat.new("white", "Bayliner", "Element", "displacement")
  # begin
  #   puts boat.honk # This raises an error - LSP violation!
  # rescue => e
  #   puts "Error: #{e.message}"
  # end

  # Where would you put an electric car? They don't have traditional engines...
  # Where would you put a drone? It flies but is it a vehicle?
  # Where would you put a skateboard? It has wheels but no engine...
end
