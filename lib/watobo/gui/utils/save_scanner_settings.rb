# @private 
module Watobo#:nodoc: all
  module Gui
    def self.save_scanner_settings()
      #puts "* saving scanner settings ..."
      #puts Watobo::Conf::Scanner.settings.to_yaml
      
      unless Watobo.project.nil?

        Watobo::Conf::Scanner.save_project(){ |s|
       #  puts s.to_yaml
          s.delete(:scan_name)
          s
        }

        session_filter = [ :sid_patterns, :logout_signatures, :custom_error_patterns, :max_parallel_checks, :excluded_parms, :non_unique_parms ]
        Watobo::Conf::Scanner.save_session(session_filter)
      return true
      else
        Watobo::Conf::Scanner.save
      end
    end
  end
end