require 'jwt'
require 'base64'


t = Time.now.to_i


payload =  JSON.parse '{ "test":"test1"}'
t = t - 24 * 3600 * 30
payload['exp'] = t + 3600
payload["iat"] = t
payload["jti"] = "1aa6a65c-c843-4b0d-b1d5-6dadbfabdeb2"

token = JWT.encode payload, '', 'HS256', {'kid'=>'rsa1'}
th, tp, ts = token.split('.')
puts Base64.decode64(th)
puts Base64.decode64(tp)
#puts Base64.decode64(ts)

puts
puts token
puts
# make signature invalid
#token[-3..-1] = 'AAA'
#puts token
puts '---'
# Invalid Token Format
#token = 'AAA.BBB.CCC'

begin
  decoded_token = JWT.decode token, '', true, { :algorithm => 'HS256',
                                                :verify_expiration => false,
  }
rescue JWT::ExpiredSignature
  puts "Signature Expired"
rescue JWT::VerificationError
  puts "Signature Invalid"
rescue JWT::DecodeError
  puts 'Invalid JWT Token Format'
end
puts decoded_token
puts decoded_token.class

# Array
# [
#   {"data"=>"test"}, # payload
#   {"alg"=>"HS256"} # header
# ]
puts decoded_token

# manual check signature
# from https://jwt.io/introduction/
=begin
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret)
=end


x = JWT.verify_signature 'HS256', '', Base64.urlsafe_encode64(decoded_token[1].to_s) + '.' + Base64.urlsafe_encode64(payload.to_s), token.split('.')[2]
puts x.class

