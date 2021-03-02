# parser for spring actuators httptrace response
#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'json'
require 'yaml'
require 'base64'
require 'openssl'
require 'optimist'
require 'pry'
require 'watobo'

# ruby bin/httptrace.rb  -c 'X-WWW-ACCESS=1' -i "['timestamp']" -i "['request']['uri']" -f /path/to/httptrace

OPTS = Optimist::options do
  version "#{$0} 1.0 (c) 2021 siberas"

  banner <<-EOS
Tool for easy parsing httptrace output.

Examples
To parse a file use:
ruby bin/httptrace.rb  -c 'X-WWW-ACCESS=1' -i "['timestamp']" -i "['request']['uri']" -f /path/to/httptrace

Or to parse a live httptrace:
httptrace.rb -u "https://vulnerable.site.io/actuator/httptrace" -i "['timestamp']" -i "['request']['uri']" -i "['request']['headers']['Cookie']" 
Usage:
       httptrace.rb [options]

where [options] are:
EOS
  opt :url, "URL of httptrace", :type => :string, :default => ''
  opt :headers, "headers", :type => :string, :multi => true
  opt :cookies, "cookie", :type => :string, :multi => true
  opt :file, "file", :type => :string, :default => ''
  opt :pattern, "url pattern, infos will only be displayed if pattern matches ['request']['uri']", :type => :string
  opt :infos, "info segments, e.g. ", :type => :string, :multi => true
  opt :pretty, "only format json to a readable format"

end

def request
  uri = URI.parse(OPTS[:url])
  puts "+ starting an ssl request to #{uri.host}:#{uri.port} ..."

  begin

    session = Watobo::Session.new
    request = Watobo::Request.new uri.to_s
    if OPTS[:cookies]
      request.add_header 'Cookie', OPTS[:cookies].join('; ')
    end

    req, response = session.doRequest(request)


    unless response.status =~ /200/
      puts "seems like the request fucked up :/"
      puts
      puts '--- R E S P O N S E ---'
      puts response.to_s
      puts '---'
      exit
    end

    return response.body
  rescue OpenSSL::SSL::SSLError => e
    puts "\n!!!\n--- SSL Error ---"
    puts e
  rescue => bang
    puts "--- F A I L U R E ---"
    puts bang
  end
end

if File.exist? OPTS[:file]
  puts "+ Loading httptrace from file #{OPTS[:file]}"
  trace = JSON.parse File.read(OPTS[:file])
else

  Optimist.die :url, 'Need Filename or URL' if OPTS[:url].empty?

  trace = JSON.parse(request)
end
traces = trace['traces']

if OPTS[:pretty]
  puts JSON.pretty_generate traces
  exit
end

traces.each do |t|

  uri = t['request']['uri']
  #if t['request']['']
  if $VERBOSE

    puts t['timestamp']
  end
  if uri =~ /#{OPTS[:pattern]}/
    puts '--- TRACE ---'
    if OPTS[:infos]
      OPTS[:infos].each do |i|
        begin
          d = eval("#{t}#{i}")
          puts "#{i}: #{d}"
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
    end
  end
end