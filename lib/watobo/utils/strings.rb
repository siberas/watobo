# @private 
module Watobo#:nodoc: all
  module Utils
    def self.camelcase(string)
      string.strip.gsub(/[^[a-zA-Z\-_]]/,"").gsub( "-" , "_").split("_").map{ |s| s.downcase.capitalize }.join
    end
    
    def self.snakecase(string)
      string.gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr("-","_").downcase
    end
  end
end