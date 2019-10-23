lambda {|response|
  h = response.body.to_s
  r = Base64.decode64(h)
  pos = 0
  pretty = ''

  while pos >= 0 and pos < r.length
    seg_end = r.index(/[^?]'/, pos)
    if seg_end
      pretty << r[pos..seg_end + 1]
      pretty << "\n"
    else
      break
    end
    pos = seg_end + 2
  end

  pretty << "\n\nPasteable\n\n"
  pretty << Base64.strict_encode64(r)

  pretty
}
