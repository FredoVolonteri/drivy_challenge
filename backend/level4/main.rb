require "Date"
require 'json'
require 'active_model'


FILE = File.read('backend/level4/data.json')

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
    JSON.pretty_generate({ rentals: rentals.map(&:rental_output) })
  end

end

class Car
  attr_accessor :id, :price_per_day, :price_per_km
  include ActiveModel::Model
end

class Rental
  attr_accessor :id, :car_id, :car, :start_date, :end_date, :distance, :deductible_reduction
  include ActiveModel::Model

  def price
    days = (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
    if days == 1
      price = (days*car.price_per_day + @distance*car.price_per_km).round
    elsif days > 1 && days <= 4
      price = (car.price_per_day*(1 + (days-1)*0.9) + @distance*car.price_per_km).round
    elsif days > 4 && days <= 10
      price = (car.price_per_day*(1 + 3*0.9 + (days-4)*0.7) + @distance*car.price_per_km).round
    elsif days > 10
      price = (car.price_per_day*(1 + 3*0.9 + 6*0.7 + (days-10)*0.50) + @distance*car.price_per_km).round
    end
    price
  end

  def commission
    days = (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
    total_commission = self.price*0.3
    insurance_fee = (total_commission/2).round
    assistance_fee = days*100
    drivy_fee = (insurance_fee - assistance_fee).round

    commission = {
          "insurance_fee": insurance_fee,
          "assistance_fee": assistance_fee,
          "drivy_fee": drivy_fee
        }
    return commission
  end

  def options
    days = (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
    deductible_reduction = 0
    if self.deductible_reduction
    deductible_reduction = days*400
  else
    deductible_reduction = 0
  end
    options = {
    "deductible_reduction": deductible_reduction
  }
  end

  def rental_output
    {id: id, price: price, options: options, commission: commission}
  end
end

output = Computation.new(FILE).process.to_json

filepath_result = 'backend/level4/my_result.json'
File.open(filepath_result, 'wb') do |file|
  file.write(output)
end

