# A messy Vehicle inheritance hierarchy
# Problems:
# - Deep inheritance chains make it rigid
# - Code duplication despite inheritance
# - Hard to add new vehicle types that don't fit the hierarchy
# - Violates LSP (Liskov Substitution Principle) in several places

class Vehicle
  attr_accessor :color, :brand, :model

  def initialize(color, brand, model)
    @color = color
    @brand = brand
    @model = model
  end

  def start_engine
    "Engine started"
  end

  def stop_engine
    "Engine stopped"
  end

  def honk
    "Beep beep!"
  end
end

class LandVehicle < Vehicle
  attr_accessor :num_wheels

  def initialize(color, brand, model, num_wheels)
    super(color, brand, model)
    @num_wheels = num_wheels
  end

  def drive
    "Driving on land"
  end
end

class WaterVehicle < Vehicle
  attr_accessor :hull_type

  def initialize(color, brand, model, hull_type)
    super(color, brand, model)
    @hull_type = hull_type
  end

  def sail
    "Sailing on water"
  end

  # Boats don't honk!
  def honk
    raise "Boats don't honk!"
  end
end

class Car < LandVehicle
  attr_accessor :num_doors

  def initialize(color, brand, model, num_doors)
    super(color, brand, model, 4)
    @num_doors = num_doors
  end

  def open_trunk
    "Trunk opened"
  end
end

class Motorcycle < LandVehicle
  def initialize(color, brand, model)
    super(color, brand, model, 2)
  end

  # Motorcycles don't have trunks
  # Can't use car methods, but they're both LandVehicles
end

class Bicycle < LandVehicle
  def initialize(color, brand, model)
    super(color, brand, model, 2)
  end

  # Bicycles don't have engines!
  def start_engine
    raise "Bicycles don't have engines!"
  end

  def stop_engine
    raise "Bicycles don't have engines!"
  end

  # Bicycles don't honk the same way
  def honk
    "Ring ring!"
  end
end

class Boat < WaterVehicle
  def initialize(color, brand, model)
    super(color, brand, model, "displacement")
  end

  def drop_anchor
    "Anchor dropped"
  end
end

class Submarine < WaterVehicle
  def initialize(color, brand, model)
    super(color, brand, model, "pressure")
  end

  def dive
    "Diving underwater"
  end

  def surface
    "Surfacing"
  end
end

# Now what about an Amphibious vehicle that can go on land AND water?
# Where does it fit in the hierarchy?
class AmphibiousVehicle < LandVehicle
  # Wait, it should also be a WaterVehicle... Ruby doesn't have multiple inheritance!
  # This is getting messy...

  def sail
    "Sailing on water"
  end

  def switch_to_water_mode
    "Switched to water mode"
  end

  def switch_to_land_mode
    "Switched to land mode"
  end
end

# And what about a Hovercraft? It hovers above land and water...
# What about a Plane? It's similar to a car but flies...
# The inheritance hierarchy is breaking down!

# Example usage that shows the problems:
if __FILE__ == $0
  car = Car.new("red", "Toyota", "Camry", 4)
  puts car.start_engine
  puts car.drive
  puts car.honk

  bike = Bicycle.new("blue", "Trek", "Mountain")
  begin
    puts bike.start_engine # This raises an error - LSP violation!
  rescue => e
    puts "Error: #{e.message}"
  end

  boat = Boat.new("white", "Bayliner", "Element", "displacement")
  begin
    puts boat.honk # This raises an error - LSP violation!
  rescue => e
    puts "Error: #{e.message}"
  end

  # Where would you put an electric car? They don't have traditional engines...
  # Where would you put a drone? It flies but is it a vehicle?
  # Where would you put a skateboard? It has wheels but no engine...
end
