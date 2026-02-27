# Solution for Stock Price Observer Challenge
# Write your solution here

class Stock
  def initialize(name, price)
    @name = name
    @price = price
    @observers = []
  end

  def attach(observer)
    @observers << observer
  end

  def detach(observer)
    @observers.delete(observer)
  end

  def set_price(new_price)
    old_price = @price
    @price = new_price
    call_observers(old_price)
  end

  def call_observers(old_price)
    @observers.each do |observer|
      observer.alert(@name, old_price, @price)
    end
  end
end

module Observer
  def alert
    raise NotImplementedError
  end
end

class PriceDropAlert
  include Observer

  def initialize(threshold_percent)
    @threshold_percent = threshold_percent
  end

  def alert(name, old_price, new_price)
    dropped_by = old_price - new_price
    dropped_by_percentage = ((dropped_by / old_price) * 100).round(2)

    if dropped_by_percentage > @threshold_percent
      puts "Alert! #{name} dropped by #{dropped_by_percentage}%"
    end
  end
end

class PriceIncreaseAlert
  include Observer

  def initialize(threshold_percent)
    @threshold_percent = threshold_percent
  end

  def alert(name, old_price, new_price)
    dropped_by = new_price - old_price
    dropped_by_percentage = ((dropped_by / old_price) * 100).round(2)

    if dropped_by_percentage > @threshold_percent
      puts "Alert! #{name} increased by #{dropped_by_percentage}%"
    end
  end
end

class Logger
  include Observer

  def alert(name, old_price, new_price)
    puts "#{name} price changed from $#{old_price} to $#{new_price}"
  end
end