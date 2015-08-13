# @private 
module Watobo#:nodoc: all::Plugin
  module Plugin
  class WShell
    @executions = Queue.new
    @history = []
HELP_TEXT =<<'EOF'
____    __    ____   _______. __    __  
\   \  /  \  /   /  /       ||  |  |  | 
 \   \/    \/   /  |   (----`|  |__|  | 
  \            /    \   \    |   __   | 
   \    /\    / .----)   |   |  |  |  | 
    \__/  \__/  |_______/    |__|  |__| 
    
Welcome to the WATOBO Shell!
Simply enter your ruby code you want to execute and press enter.
To get your output written to the textbox use the <out> stream, e.g. 
out << "Hello World"
For command history use Up- and Down-Keys.
A good starting point to explore WATOBO is the Watobo object itself.

Example 1: List all sites
>> Watobo::Chats.sites do |s| out << "#{s}\n";end

Example 2: Get all values of URL parameter <raid>
>> Watobo::Chats.each do |c| v = c.request.get_parm_value('raid'); out << "#{v}\n" unless v.empty?;end

Example 3: List all URL where chat comment contains 'Session-Test'
>> out << Watobo::Chats.map { |c| c.comment =~ /Session-Test/i ? c.request.url : nil }.compact.join("\n")

EOF
         
    def self.help
      HELP_TEXT
    end
     
    def self.executions
      @executions
    end
    
    
    def self.history_length
      @history.length
    end
    
    def self.history_at(index)
      if index >= 0 and index < @history.length
        return @history[index]
      end
      return nil
    end
    
    def self.execute_cmd(command)
      
       Thread.new(command){ |cmd|
         begin
           @history << cmd unless @history.include? cmd
           @history.shift if @history.length > 20
           
           command = "out = StringIO.new; #{cmd}; out.string"
           r = eval(command)           
                       
           @executions << [ cmd, r ]
         rescue SyntaxError, LocalJumpError, NameError => e
           out = e.to_s
           out << e.backtrace.join("\n")
           @executions << [ cmd, "#{out}" ]
         rescue => bang
           puts bang.backtrace
           @executions << [ cmd, bang ]
           
         end
       }
    end
    
    
    end
  end
end

