# @private 
module Watobo#:nodoc: all
  module Utils
    
    def Utils.secure_eval(exp)
      result = nil
      t = Thread.new(exp) { |e|
        e.untaint
        $SAFE = 0
     #   $SAFE = 3 # no longer supported since ruby 2.3
     #   $SAFE = 4 # no longer supported since ruby 2.1.x
        begin
          
         result = eval(e)
         
      
        rescue SyntaxError => bang
          puts bang
      puts bang.backtrace if $DEBUG
        rescue LocalJumpError => bang
          puts bang
      puts bang.backtrace if $DEBUG
        rescue SecurityError => bang
          puts "WARNING: Desired functionality forbidden. it may harm your system!"
          puts bang.backtrace if $DEBUG
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          
        end
      }
      t.join
      return result
     
    end
    
  end
end
