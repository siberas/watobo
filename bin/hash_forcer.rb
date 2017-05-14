#!/usr/bin/ruby
require 'yaml'
require 'cgi'
require 'uri'

=begin LINKS
* http://blog.nathanielbibler.com/post/63031273/openssl-hmac-vs-ruby-hmac-benchmarks
=end

=begin EXAMPLE 1
URL: http://www.somewhe.re/aaa?hash=RJ7zik4RVAtHYyC3iLAWdHbHqBs(1&ff=img&ref=74589002
JSESSIONID = 457B2B6F9D75344B6C9EA4DB69B76D73
=>
hash_forcer.rb -m "RJ7zik4RVAtHYyC3iLAWdHbHqBs=" -s "457B2B6F9D75344B6C9EA4DB69B76D73" -p "457B2B6F9D75344B6C9EA4DB69B76D73" "ff=img&ref=74589002"
=end

=begin EXAMPLE 2
>hash_forcer.rb -m "nP01Y4W/v8+aNU7cApnbZA==" test oans zwoa drei gsuffa

---
FS: ["", ":", "-", "|", "+", "="]
Normalize Match String ...
Input: nP01Y4W/v8+aNU7cApnbZA==
Norma: nP01Y4W/v8+aNU7cApnbZA==

INPUT: test, oans, zwoa, drei, gsuffa

NUM COMBINATIONS: 30

Perform Permutations ...
[16602] gsuffadreizwoaoans

NUM PERMUTATIONS: 2640
Trying ...

[007] test:drei
GOTCHA! [MD5] - ["test", "drei"]

F:\Projects\watobo\tools>
=end

if $0 == __FILE__
  begin
    require 'devenv'
  rescue LoadError
    inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
  end
end

require 'optparse'

$fs = %w( : - | + = )
$fs.unshift ''

$match = nil

$suffixes = $prefixes = []

opts = OptionParser.new do |o|
  o.banner = "Usage: #{File.basename($0)} [OPTIONS] INPUT"
  o.separator ""
  o.separator "OPTIONS"

  o.on( "-v", "--verbose", "detailed output." ) do |v|
    $VERBOSE = v
  end

  o.on( "-t", "--type TYPE", "Input TYPE, e.g. HTTP_REQUEST" ) do |v|
    $type = v
  end

  o.on( "-h", "--hash HASH", "HASH Type, e.g. HMAC-MD5, SHA-1" ) do |v|
    $hash_type = v
  end

  o.on( "-k", "--key KEY1,..,KEYn", Array, "Hashing Keys if neccessary, like HMAC-MD5" ) do |v|
    $keys = v
  end

  o.on( "-f", "--fs fs1,..,fsn", Array, "FieldSeparators, used when joining values [#{$fs.join(',')}]" ) do |v|
    $fs = v
  end

  o.on( "-s", "--suffixes s1,..,sn", Array, "Suffixes will be appended before calculation" ) do |v|
    $suffixes = v
  end
  o.on( "-p", "--prefixes p1,..,pn", Array, "Prefixes will be prepended before calculation" ) do |v|
    $suffixes = v
  end

  o.on( "-m", "--match MATCH", "Value to match against" ) do |v|
    $match = v
  end

  o.on("-h","--help","help") do
    puts opts
  end

end

puts
puts "---"
opts.parse!( ARGV )

require 'digest'
require 'digest/sha2'
require 'digest/sha1'
require 'digest/md5'
require 'digest/rmd160'
require 'base64'

$total = 0
puts "FS: #{$fs}"
puts "Normalize Match String ..."
puts "Input: " + $match
$match_dec64 = Base64.decode64 $match
$nrm = Base64.strict_encode64 $match_dec64
puts "Norma: " + $nrm

if $match != $nrm
  puts
  puts "WARNING:  Normalized Match String Differs!"
end
puts
$match = $nrm

def match(data)
  hashes = {}
  #puts
  $fs.each do |f|
    data_str = data.join(f)
    #     puts data_str
    $total += 1
    if data_str.length >= 40
    out_str = data_str[0..39]
    else
      out_str = data_str + " " * (40 - data_str.length)
    end
    #printf "\r[%.03d] %s", ( ($total * 100)/ $num_permutations), "#{data_str[0..40]}" + " "*(40-data_str.length)
    printf "\r[%03d] %s", ( ($total * 100)/ $num_permutations), out_str

    Digest.constants.each do |digest|
      next if digest =~/(instance|class|Base)/i

      hash = eval("Digest::#{digest.to_s}.digest(data_str)")

      #puts digest.to_s + " : " + hash.length.to_s
      hashes[digest.to_sym] = hash
    end

    hashes.each do |m, h|
      b64 = Base64.strict_encode64(h)

      # puts "* [#{m}] #{b64}"
      if b64.strip == $match.strip
        puts
        puts "GOTCHA! [#{m}] - #{data}"
        exit
      end
    end
  end
end

def check_suffixed(input)
  $fs.each do |fs|
    base = input.join(fs)

    $suffixes.each do |suf|
      data = "#{base}"
      data << fs
      data << suf
      match data
    end
  end
end

def check_prefixed(input)

  $fs.each do |fs|
    base = input.join(fs)
    $prefixes.each do |pref|
      data = [ pref ]
      data << fs
      data << "#{base}"
      match data
    end
  end
end

def check_counter(input)
  $fs.each do |fs|
    base = input.join(fs)
    max_count = 1000
    max_count.times do |i|
      data = "%0.#{max_count.to_s.length}i" % i
      data << fs
      data << "#{base}"
      match data
    end
    max_count.times do |i|
      data = "#{base}"
      data << fs
      data << "%0.#{max_count.to_s.length}i" % i

      match data
    end
  end

end

def check_all(data)
  # print "."
  match data
  check_suffixed data
  check_prefixed data
end

input = ARGV[0]
check_values = []

input_values = []
if ARGV.length >= 1
  ARGV.each do |v|
    input_values << v
  end
end

puts "INPUT: " + input_values.join(", ")

value_sets = []
if input_values.length > 1
  (input_values.length-1).times do |i|
    input_values.repeated_combination(i+1).each do |combi|
    # we don't want double entries
      value_sets << combi if combi.length == combi.uniq.length
    end
  end
elsif input_values.length > 0
value_sets << input_values
else
  exit
end

value_sets.uniq!

puts
puts "NUM SETS: #{value_sets.length}"
puts value_sets.to_yaml if $VERBOSE
puts

x = value_sets.inject(0){ |s, combo|
  s + combo.permutation.to_a.length ** 4
}
$num_permutations =  x * ( $fs.length + 4 )
puts "EST.NUM. PERMUTATIONS: #{$num_permutations}"

puts
puts "Trying ..."

value_sets.each do |combo|

  combo.permutation do |p|
    #puts "\n(#{p.class}) #{p}"
  #
  #printf "\r[%d] %s", check_values.length, p.join.slice(0,50)
    check_all p
    
    upcased = p.map{|v| v.upcase }

    check_all upcased
    #check_values.concat upcased[0..-2].product(p[1..-1])

    upcased.product(p).to_a.uniq.map{|v| check_all v }

    downcased = p.map{|v| v.downcase }
    check_all downcased
    ##check_values.concat downcased[0..-2].product(p[1..-1])
    downcased.product(p).to_a.uniq.map{|v| check_all v }

    uri_escaped = p.map{|v| CGI.escape(v).gsub("+", "%20") }
    check_all uri_escaped
    #check_values.concat uri_escaped[0..-2].product(p[1..-1])
    uri_escaped.product(p).to_a.uniq.map{|v| check_all v }

    #uri_unescaped = p.map{|v| URI.decode_www_form_component(v) }
    #check_all uri_unescaped
    #check_values.concat uri_unescaped[0..-2].product(p[1..-1])
    #uri_unescaped.product(p).to_a.uniq.map{|v| check_all v }

    cgi_escaped = p.map{|v| CGI.escape(v) }
    check_all cgi_escaped
    #check_values.concat cgi_escaped[0..-2].product(p[1..-1])
    cgi_escaped.product(p).to_a.uniq.map{|v| check_all v }

    cgi_unescaped = p.map{|v| CGI.unescape(v) }
    check_all cgi_unescaped
    #check_values.concat cgi_unescaped[0..-2].product(p[1..-1])
    cgi_unescaped.product(p).to_a.uniq.map{|v| check_all v }

  end
end

puts
puts "Total Checks: #{$total}"
