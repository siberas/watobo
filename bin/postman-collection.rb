require 'json'
require 'csv'

# Define the input JSON file and output CSV file
input_file = ARGV[0]
output_file = '/tmp/postman_collection.csv'

# Read and parse the Postman collection JSON file
collection = JSON.parse(File.read(input_file))

# Initialize an array to store the extracted data
data = []

# Recursively process items in the collection
def process_items(items, data, parent_name = nil)
  items.each do |item|
    if item['item'] # Nested items
      process_items(item['item'], data, item['name'])
    else
      # Extract method, path, and description
      method = item.dig('request', 'method') || 'N/A'
      path = item.dig('request', 'url', 'raw') || 'N/A'
      description = item['name'] || parent_name || 'N/A'
      data << [method, path, description]
    end
  end
end

# Process the root items in the collection
process_items(collection['item'], data)

# Write the data to a CSV file
CSV.open(output_file, 'w') do |csv|
  csv << ['Method', 'Path', 'Description']
  data.each do |row|
    csv << row
  end
end

puts "CSV file generated: #{output_file}"
