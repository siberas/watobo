#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end

require 'base64'
require 'openssl'
require 'optimist'
require 'pry'
require 'net/http'

OPTS = Optimist::options do
  version "#{$0} 1.0 (c) 2020 siberas"
  opt :cert, " can be Filename or a Base64 String (DER or PEM)", :type => :string
  opt :subject, "Subject value", :type => :string
  opt :new, "create new certificate. Subject and Issuer required!"
  opt :text, "show only the content of a given certificate. Does not create a new one."
  opt :issuer, "Issuer value", :type => :string
  opt :key, "private key of original certificate. Needed if you want to make a simple request test.", :type => :string
  opt :request, "make a test request with the original request and exit - a key is required."
  # opt :date, "Date of expiration (timestamp value)", :type => :string
  opt :out, "Filename", :type => :string
  opt :format, "Output format", :type => :string, :default => 'pem'
  opt :extensions, "add one or more extensions. name and value seperated by first colon, e.g. basicConstraints:CA:TRUE", :type => :strings, :multi => true
  opt :days_valid, "Set number of days the certificate is valid in days from now, e.g. 365 for one year", :type => :string
  opt :url, "URL for testing with the spoofed certificate", :type => :string, :default => ''
end


new_cert = nil
if OPTS[:text]
  Optimist::die :cert, "cert missing! need a certificate (file or base64 encoded)" unless OPTS[:cert]

  data = OPTS[:cert]
  source = 'Base64'

  if File.exist?(data)
    source = "FILE"
    data = File.read(data)
  else
    data = Base64.decode64(OPTS[:cert])
  end
  new_cert = OpenSSL::X509::Certificate.new data
  puts new_cert.to_text
  exit
end

if OPTS[:request]
  Optimist::die :cert, "cert missing! need a certificate (file or base64 encoded)" unless OPTS[:cert]
  Optimist::die :key, "key file is required for making a request!" unless OPTS[:key]

  data = OPTS[:cert]
  source = 'Base64'
  if File.exist?(data)
    source = "FILE"
    data = File.read(data)
  else
    data = Base64.decode64(OPTS[:cert])
  end
  client_cert = OpenSSL::X509::Certificate.new data

  req_opts = {
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
      cert: client_cert,
      key: OpenSSL::PKey::RSA.new(File.read(OPTS[:key]))
  }
  begin
    uri = URI.parse(OPTS[:url])
    https = Net::HTTP.start(uri.host, uri.port, req_opts)
    response = https.request Net::HTTP::Get.new uri.path
    puts '--- R E S P O N S E ---'
    puts "#{response.code} #{response.msg}"
    response.each_header do |k,v|
      puts "#{k}: #{v}"
    end
    puts response.body
    exit
  rescue => bang
    puts bang
  end
  exit
end

if OPTS[:new]

  Optimist::die :subject, "subject missing! need subject and issuer when creating a new certificate" unless OPTS[:subject]
  Optimist::die :issuer, "issuer missing! need subject and issuer when creating a new certificate" unless OPTS[:issuer]
  new_cert = OpenSSL::X509::Certificate.new
  fields = OPTS[:subject].split(/[,\/]/)
  #binding.pry
  new_subject = fields.map { |f| n, v = f.split('='); n.nil? ? nil : [n.strip, v.strip] }
  new_subject.compact!
  new_cert.subject = OpenSSL::X509::Name.new(new_subject)

  fields = OPTS[:issuer].split(/[,\/]/)
  issuer = fields.map { |f| n, v = f.split('='); n.nil? ? nil : [n.strip, v.strip] }
  issuer.compact!
  new_cert.issuer = OpenSSL::X509::Name.new(issuer)

  from = Time.now
  new_cert.not_before = from
  new_cert.not_after = from + 365 * 24 * 60 * 60
  new_cert.serial = 666
  new_cert.version = 2 # X509v3
else
  Optimist::die :cert, "cert missing! need a certificate (file or base64 encoded)" unless OPTS[:cert]

  data = OPTS[:cert]
  source = 'Base64'
  if File.exist?(data)
    source = "FILE"
    data = File.read(data)
  else
    data = Base64.decode64(OPTS[:cert])
  end
  new_cert = OpenSSL::X509::Certificate.new data
  if OPTS[:subject]
    puts "+ create new certificate from #{source}"
    puts "+ set new subject"
    fields = OPTS[:subject].split(/[,\/]/)
    new_subject = fields.map { |f| n, v = f.split('='); [n.strip, v.strip] }
    new_cert.subject = OpenSSL::X509::Name.new(new_subject)
  end
end

if OPTS[:days_valid]
  new_cert.not_after = Time.now + OPTS[:days_valid].to_i * 24 * 60 * 60
end

ef = OpenSSL::X509::ExtensionFactory.new
OPTS[:extensions].each do |ext|
  begin
    n, v = ext[0].split(':', 2)
    puts "Add extension: #{n} - #{v}" if $VERBOSE
    new_cert.add_extension ef.create_extension(n, v)
  rescue => bang
    puts bang
    binding.pry if $DEBUG
    exit
  end
end

puts '+ create new keypair'
keypair = OpenSSL::PKey::RSA.new(2048)
puts '+ sign certificate with new keypair'
new_cert.public_key = keypair.public_key
new_cert.sign keypair, OpenSSL::Digest::SHA256.new

outfile = "/tmp/fake_cert_#{Time.now.to_i}.pem"
File.open(outfile, 'w') { |fh| fh << new_cert.to_pem }

#binding.pry

new_cert_b64 = Base64.strict_encode64 new_cert.to_der
puts new_cert.to_text
puts "DER-Format (Base64):"
puts new_cert_b64
puts "+ cert has been written to #{outfile}"

unless OPTS[:url].empty?
  uri = URI.parse(OPTS[:url])
  puts "+ starting an ssl request to #{uri.host}:#{uri.port} ..."
  req_opts = {
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
      cert: new_cert,
      key: keypair
  }
  begin

    https = Net::HTTP.start(uri.host, uri.port, req_opts)
    response = https.request Net::HTTP::Get.new uri.path
    puts '--- R E S P O N S E ---'
    puts "#{response.code} #{response.msg}"
    response.each_header do |k,v|
      puts "#{k}: #{v}"
    end
    puts response.body
  rescue OpenSSL::SSL::SSLError => e
    puts "\n!!!\n--- SSL Error (which is probably a good sign ;) ---"
    puts e
  rescue => bang
    puts "--- F A I L U R E ---"
    puts bang
    binding.pry
  end

end