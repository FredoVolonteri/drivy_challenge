require "json"
require "Date"
require 'json'
require 'active_model'


FILE = File.read('backend/level1/data.json')

class Computation

  attr_accessor :data, :cars, :rentals
  def initialize(data)
    @data = JSON.parse(data) # It's a hash
    @cars = @data["cars"].map { |car| Car.new(car)} # Data["cars"] array of hashes with car parameters
    @rentals = @data["rentals"].map do |rental|
      Rental.new(rental.merge(car: @cars.find { |c| c.id == rental["car_id"]}))
    end
  end

  def process
    rentals.map(&:price)
    self
  end

  def to_json

    p rentals.map(&:rental_output)

    JSON.pretty_generate({ rentals: rentals.map(&:rental_output) })
  end

end

class Car
  attr_accessor :id, :price_per_day, :price_per_km
  include ActiveModel::Model
end

class Rental
  attr_accessor :id, :car_id, :car, :start_date, :end_date, :distance
  include ActiveModel::Model

  def price
    price = (((Date.parse(end_date) - Date.parse(start_date)).to_i + 1)* car.price_per_day + @distance*car.price_per_km)
  end

  def rental_output
    {id: id, price: price}
  end
end

output = Computation.new(FILE).process.to_json

filepath_result = 'backend/level1/my_result.json'
File.open(filepath_result, 'wb') do |file|
  file.write(output)
end


















