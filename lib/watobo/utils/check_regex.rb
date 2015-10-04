# @private 
module Watobo#:nodoc: all
  module Utils
    def Utils.checkRegex(pattern)
      begin
        # use nice string to test pattern ;)
        "watobo rocks!!!" =~ /#{pattern}/i
        return true
      rescue => bang
       # puts bang
        return false, bang
      end
    end
    
  end #--- Utils
end #---Watobo
