module URI
  class HTTP
    def to_file
      fname = []
      #fname << scheme
      fname << host
      fname << port
      fname.join('_').gsub(/[\-\.]/, '_').downcase
    end
  end
end