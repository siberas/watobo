```
require "selenium-webdriver"
require 'pry'
require 'optimist'

OPTS = Optimist::options do
  version '(c) 2022 Watobo Sp1dR'
  banner <<-EOS


EOS

  opt :url, "set WATOBO_HOME aka working_directory", :type => :string, :default => ENV['WATOBO_HOME']
  opt :proxy, "Proxy (host:port)", :type => :string
end

# configure the driver to run in headless mode
options = Selenium::WebDriver::Chrome::Options.new
#options.add_argument('--headless')

if OPTS[:proxy]
options.add_argument('--proxy-server=%s' % PROXY)
end

driver = Selenium::WebDriver.for :chrome, options: options

start_url = OPTS[:url]
collection = []
visited = []
executed = []

start_uri = URI.parse(start_url)


collection << start_url

while collection.length > 0
  check_url = collection.shift
  driver.navigate.to check_url
  visited << check_url

  puts "Analyzing #{check_url}"
  puts "Visited: #{visited}"
  uri = URI.parse(check_url)
  current_host = uri.host

all = driver.find_elements(:xpath, './/*')
all_attributes = {}
all.each do |e|
  all_attributes[e] = driver.execute_script("var items = {}; for (index = 0; index < arguments[0].attributes.length; ++index) { items[arguments[0].attributes[index].name] = arguments[0].attributes[index].value }; return items;", e );
end

  # simple href collection
   hrefs = driver.find_elements(:tag_name, 'a')
   hrefs.map{|h| h.attribute('href') }.each do |href|
    uri = URI.parse href
    uri.fragment = nil
    url = uri.to_s
     if url =~ /^.{1,5}:\/\/[^[:\/]]*#{start_uri.host}/

         collection << url unless visited.include?(url)
     end
   end

   collection.uniq!


buttons =driver.find_elements(:tag_name, 'button')
btn_attributes = {}

buttons.each do |b|
  btn_attributes[b] = driver.execute_script("var items = {}; for (index = 0; index < arguments[0].attributes.length; ++index) { items[arguments[0].attributes[index].name] = arguments[0].attributes[index].value }; return items;", b);
end

btn_attributes.each do |btn, attrs|
  #puts btn
  ##puts attrs
end

end
binding.pry
```