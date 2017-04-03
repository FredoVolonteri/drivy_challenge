require "json"
require "Date"

# your code

 # JSON Parsing
filepath = 'backend/level1/data.json'
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
  price_per_day = 0
  price_per_km = 0
  cars_array.each do |car|
    if car["id"] == car_id
      price_per_day = car["price_per_day"]
      price_per_km = car["price_per_km"]
    end
  end
  price = (((Date.parse(items["end_date"]) - Date.parse(items["start_date"])).to_i + 1)* price_per_day + items["distance"]*price_per_km)
  output_hash["rentals"] << {"id": items["id"], "price": price }
end
# Storing the hash into json
filepath_result = 'backend/level1/my_result.json'
File.open(filepath_result, 'wb') do |file|
  file.write(JSON.pretty_generate(output_hash))
end
