lambda{|response|
  begin
    jb = JSON.parse(response.body.to_s)
    out = JSON.pretty_generate jb
  rescue => bang
    out = "Could prettify response :(\n\n"
    out << bang.to_s
  end
  out  
}