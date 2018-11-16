lambda{|response|
  h = response.body.to_s
  r = Base64.decode64(h)
  r.split(/[^?]'/).join("'\n")
}
