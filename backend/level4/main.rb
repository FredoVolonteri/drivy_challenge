require "json"
require "Date"
 # JSON Parsing
filepath = 'backend/level4/data.json'
serialized_data = File.read(filepath)
data_hash = JSON.parse(serialized_data)

# Separate cars and rentals info in data_hash for easy manipulation
cars_array = data_hash["cars"]
rentals_array = data_hash["rentals"]
output_hash = {} # initialize empty hash
output_hash["rentals"] = [] # initialize empty array as the value of the key "rentals"

# go through the rentals_array to compute pricing
rentals_array.each do |items|
  car_id = items["car_id"]
  price_per_day_initial = 0
  price_per_km = 0
  cars_array.each do |car|
    if car["id"] == car_id
      price_per_day_initial = car["price_per_day"]
      price_per_km = car["price_per_km"]
    end
  end
  days = (Date.parse(items["end_date"]) - Date.parse(items["start_date"])).to_i + 1
  if days == 1
    price = (days*price_per_day_initial + items["distance"]*price_per_km).round
  elsif days > 1 && days <= 4
    price = (price_per_day_initial*(1 + (days-1)*0.9) + items["distance"]*price_per_km).round
  elsif days > 4 && days <= 10
    price = (price_per_day_initial*(1 + 3*0.9 + (days-4)*0.7) + items["distance"]*price_per_km).round
  elsif days > 10
    price = (price_per_day_initial*(1 + 3*0.9 + 6*0.7 + (days-10)*0.50) + items["distance"]*price_per_km).round
  end
  if items["deductible_reduction"]
    deductible_reduction = days*400
  else
    deductible_reduction = 0
  end

  total_commission = price*0.3
  insurance_fee = (total_commission/2).round
  assistance_fee = days*100
  drivy_fee = (insurance_fee - assistance_fee).round

  commission = {
        "insurance_fee": insurance_fee,
        "assistance_fee": assistance_fee,
        "drivy_fee": drivy_fee
      }

  options = {
    "deductible_reduction": deductible_reduction
  }
  output_hash["rentals"] << {"id": items["id"], "price": price, "options": options,  "commission": commission }
end

# Storing the hash into json
filepath_result = 'backend/level4/my_result.json'
File.open(filepath_result, 'wb') do |file|
  file.write(JSON.pretty_generate(output_hash))
end
