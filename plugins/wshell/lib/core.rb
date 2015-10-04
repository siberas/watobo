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

For command history use Up- and Down-Keys.
A good starting point to explore WATOBO is the Watobo object itself.

Example 1: List all sites
>> Watobo::Chats.sites.join("\n")

Example 2: Get all values of URL parameter <raid>
>> Watobo::Chats.each do |c| v = c.request.get_parm_value('raid'); out << "#{v}\n" unless v.empty?;end

Example 3: List all URL where chat comment contains 'Session-Test'
>> out << Watobo::Chats.map { |c| c.comment =~ /Session-Test/i ? c.request.url : nil }.compact.join("\n")

EOF

      def self.help
        HELP_TEXT
      end

    end
  end
end

