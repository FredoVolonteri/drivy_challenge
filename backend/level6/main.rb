require "Date"
require 'json'
require 'active_model'


FILE = File.read('backend/level6/data.json')

class Computation
  attr_accessor :data, :cars, :rentals, :rental_modifications
  def initialize(data)
    @data = JSON.parse(data) # It's a hash
    @cars = @data["cars"].map { |car| Car.new(car)} # Data["cars"] array of hashes with car parameters
    @rentals = @data["rentals"].map do |rental|
      Rental.new(rental.merge(car: @cars.find { |c| c.id == rental["car_id"]}))
    end
    @rental_modifications = @data["rental_modifications"].map do |modif|
      RentalModification.new(modif.merge(rental: @rentals.find {|r| r.id == modif["rental_id"]}))
    end
  end

  def process
    rentals.map(&:price)
    rental_modifications.map(&:modif_price)
    self
  end

  def to_json
    JSON.pretty_generate({ rentals: rentals.map(&:rental_output) })
  end

  def to_json_modif
    JSON.pretty_generate({ rental_modifications: rental_modifications.map(&:modif_output) })
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
    days = self.days
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

  def days
    days = (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
  end

  def commission
    commission = self.price*0.3
  end

  def insurance_fee
    insurance_fee = (self.commission/2).round
  end
  def assistance_fee
    assistance_fee = self.days*100
  end

  def deductible
    deductible_reduction = 0
    if self.deductible_reduction
    deductible_reduction = self.days*400
  else
    deductible_reduction = 0
  end
    deductible_reduction
  end

  def drivy_fee
    drivy_fee = (self.insurance_fee - self.assistance_fee).round
  end
  def actions
    total_commission = self.price*0.3
    insurance_fee = self.insurance_fee
    assistance_fee = self.assistance_fee
    drivy_fee = (insurance_fee - assistance_fee).round
    actions = [
        {
          "who": "driver",
          "type": "debit",
          "amount": price + self.deductible
        },
        {
          "who": "owner",
          "type": "credit",
          "amount": (price - total_commission).round
        },
        {
          "who": "insurance",
          "type": "credit",
          "amount": insurance_fee
        },
        {
          "who": "assistance",
          "type": "credit",
          "amount": assistance_fee
        },
        {
          "who": "drivy",
          "type": "credit",
          "amount": drivy_fee + self.deductible
        }
      ]
  end

  def rental_output
    {id: id, actions: actions}
  end
end

class RentalModification
  include ActiveModel::Model
  attr_accessor :id, :rental_id, :rental, :start_date, :end_date, :distance

  def new_start_date
    new_start_date = (start_date == nil) ? rental.start_date : start_date
  end

  def new_end_date
    ew_end_date = (end_date == nil) ? rental.end_date : end_date
  end

  def new_distance
    new_distance = (distance == nil) ? rental.distance : distance
  end

  def days
    days = (Date.parse(self.new_end_date) - Date.parse(self.new_start_date)).to_i + 1
  end

  def modif_price
    days = self.days
    if days == 1
      modif_price = (days*rental.car.price_per_day + new_distance*rental.car.price_per_km).round
    elsif days > 1 && days <= 4
      modif_price = (rental.car.price_per_day*(1 + (days-1)*0.9) + new_distance*rental.car.price_per_km).round
    elsif days > 4 && days <= 10
      modif_price = (rental.car.price_per_day*(1 + 3*0.9 + (days-4)*0.7) + new_distance*rental.car.price_per_km).round
    elsif days > 10
      modif_price = (rental.car.price_per_day*(1 + 3*0.9 + 6*0.7 + (days-10)*0.50) + new_distance*rental.car.price_per_km).round
    end
    modif_price
  end

  def modif_deductible
    days = self.days
    modif_deductible_reduction = 0
    if rental.deductible_reduction
    modif_deductible_reduction = days*400
    else
      modif_deductible_reduction = 0
    end
      modif_deductible_reduction
  end

  def new_total_commission
    new_total_commission = self.modif_price*0.3
  end

  def new_insurance_fee
    new_insurance_fee = (self.new_total_commission/2).round
  end

  def new_assistance_fee
    new_assistance_fee = self.days*100
  end
  def modif_actions
    days = self.days
    new_total_commission = self.new_total_commission
    new_insurance_fee = self.new_insurance_fee
    new_assistance_fee = self.new_assistance_fee
    new_drivy_fee = (new_insurance_fee - new_assistance_fee).round
    modif_actions = [
        {
          "who": "driver",
          "type": ((self.modif_price + self.modif_deductible) - (rental.price + rental.deductible)) < 0 ? "credit" : "debit",
          "amount": ((self.modif_price + self.modif_deductible) - (rental.price + rental.deductible)).abs
        },
        {
          "who": "owner",
          "type": ((self.modif_price - new_total_commission) - (rental.price - rental.commission)) > 0 ? "credit" : "debit",
          "amount": ((self.modif_price - new_total_commission) - (rental.price - rental.commission)).round.abs
        },
        {
          "who": "insurance",
          "type": ((new_insurance_fee) - (rental.insurance_fee)) > 0 ? "credit" : "debit",
          "amount": ((new_insurance_fee) - (rental.insurance_fee)).abs
        },
        {
          "who": "assistance",
          "type": ((new_assistance_fee) - (rental.assistance_fee)) > 0 ? "credit" : "debit",
          "amount": ((new_assistance_fee) - (rental.assistance_fee)).abs
        },
        {
          "who": "drivy",
          "type": ((new_drivy_fee + self.modif_deductible ) - (rental.drivy_fee + rental.deductible)) > 0 ? "credit" : "debit",
          "amount": ((new_drivy_fee + self.modif_deductible ) - (rental.drivy_fee + rental.deductible)).abs
        }
      ]

  end

  def modif_output
    {id: id, rental_id: rental_id, actions: modif_actions}

  end
end

output = Computation.new(FILE).process.to_json_modif

filepath_result = 'backend/level6/my_result.json'
File.open(filepath_result, 'wb') do |file|
  file.write(output)
end



















