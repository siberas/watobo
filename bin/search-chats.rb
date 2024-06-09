#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'optimist'

# ruby bin/search-chats.rb -p ~/.watobo/workspace/xxx/s1/conversations -c ~/.watobo/search_handlers/dwrextract.rb
# SearchHandler needs only the .run method which takes a chat as an parameter
#
# Example:
=begin

module SearchHandler
 def self.run(chat)
   @results ||= []
   body = chat.response.body
   if body && body.match?(/_execute\("/)
      offset = 0
      while i = body.index(/_execute\("/i, offset)
        mstart = body.index(/\(/, i)
        mend = body.index(/\)/, mstart)

       mcall = body[mstart+1..mend-1]
       mparms = mcall.split(',')
       if mparms.length >= 3
          r = [ chat.request.origin ]
          mparms.map!{|p| p.strip}
          mparms.map!{|p| p.gsub('"','') }
          r.concat mparms
          rstr = r.join(':')
          unless @results.include?(rstr)
            puts rstr
            @results << r.join(':')
          end

       end

      offset = mend + 1

      end
   end

 end
end

=end

OPTS=Optimist::options do
  version "#{$0} 0.1 (c) 2014 siberas"
  opt :url, "URL pattern", :type => :string, :default => '.*'
  opt :path, "Pathname of directory containing the chat files", :type => :string
  opt :response_pattern, "Regex to filter response (header and body)", :type => :string, :default => '.*'
  opt :request_pattern, "Regex to filter request (header and body)", :type => :string, :default => '.*'
  opt :custom_handler, "path to custom handler, which is called on", :type => :string
end

Optimist.die :path, "Need path to chat files" unless OPTS[:path]
raise "Path not found" unless File.exist?(OPTS[:path])

require 'watobo'

module SearchHandler;end
if OPTS[:custom_handler]
  Kernel.load OPTS[:custom_handler] if File.exist?(OPTS[:custom_handler])
end

def load(path, &block)
  begin
    puts "loading chats from path #{path}"
    Dir.glob("#{path}/*.mrs").each do |fname|
      chat = ::Watobo::Utils.loadChatMarshal(fname)
      yield chat if block_given?
    rescue => bang
      puts bang
      binding.pry
    end
  end
end

load(OPTS[:path]) do |chat|
  #puts chat.request.path_ext
  SearchHandler.run(chat) if SearchHandler.respond_to?(:run)
end



