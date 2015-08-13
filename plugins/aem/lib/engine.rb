# @private 
module Watobo#:nodoc: all
  module Plugin
    class CQ5
      @max_agents = 10
      @disp_queue = Queue.new
      @work_queue = Queue.new
      @gui_queue = Queue.new
      
      @agents = []
      @use_relative_path = false
      
      
      def self.reset
        @disp_queue.clear
        @work_queue.clear
        @agents.map {|a| a.stop }
        @agents = []
      end
      
      def self.ignore_patterns=(ipats)
        @ignore_patterns = ipats
      end
      
      def self.ignore_patterns
        @ignore_patterns
      end
      
            
      def self.use_relative_path=(urp)
        @use_relative_path = urp
      end
      
      def self.queue_size
        @work_queue.size
      end
      
      def self.status
        
      end
      
      def self.running?
        @work_queue.size == 0 &&
        @work_queue.num_waiting == @max_agents        
      end
      
      def self.stop
          @agents.map {|a| a.stop }
      end
      
      def self.run(start_path, gui_queue=nil)
        @agents = []
        puts "\nCQ5 Engine running on #{start_path}"
        @dispatcher = Dispatcher.new( @disp_queue, @work_queue, gui_queue )
        @dispatcher.run
        
        vr = find_valid_request(start_path)
        unless vr.nil?
          puts "Baseline Request: " + vr.url.to_s
         
          @max_agents.times do 
            puts " * Start Agent"
            a = Agent.new( vr.copy, @work_queue, @disp_queue )
            @agents << a
            a.run
          end
          
          
        else
          return false
        end
        
        
      end
      
      def self.get_user_info
        # https://mysite/cqa/libs/cq/security/userinfo.json?cq_ck=1427468388796
      end
      
      def self.find_valid_request(start_path)
        # create a dummy agent to make test requests
        agent = Agent.new nil, nil, nil
        checked = []
        #puts start_path.class
        valid_request = nil
        
        Watobo::Chats.to_a.reverse.each do |chat|
          next unless chat.request.method_get?
          url = chat.request.url.to_s
        #  url.gsub!(chat.request.site, chat.request.host)
          path = chat.request.path
          
        #  next if checked.include? path
          
          checked << path 
         # puts path.class
         # puts url.class
         # puts start_path
         # puts url
          
          pattern = Regexp.quote(start_path)
          pattern = start_path
          #puts pattern
          
          #puts "---\n"
 
          if url =~ /#{pattern}/
            test = chat.copyRequest
            test.replaceFileExt('.pages.json')
            
             
            puts "* [#{chat.id}] " + test.url.to_s
            
            request, response = agent.doRequest test
            
           # puts response
            
            unless response.content_type =~ /json/i
              puts "! .pages.json is filtered !"
              next
            end
            ntpages = JSON.parse response.body.to_s
            if ntpages['pages']
              valid_request = test
                            
              ntpages['pages'].each do |p|
                # check if escapedPath is absolut or relativ
                # if we find directory separator '/' we assume it's absolute
                ep = p['escapedPath'].gsub(/^\//,'').strip
                puts "EscapedPath: #{ep}"
                
                # find the home directory of the application
                ep_dirs = ep.split('/')
                
                puts "EscapedPath-Dirs (#{ep_dirs.length}): " + ep_dirs.join("\n")
                # request dir
                r_dir = "#{test.dir}"
                puts "Test-Request-Dir: " + r_dir
                puts "Check for #{ep_dirs[0]}, #{ep_dirs[1]}"
                # find offset of first escapePath directory
                i = r_dir.index( ep_dirs.first )
                puts "Index: #{i}"
                base_dir = r_dir
                puts base_dir
                unless i.nil?
                  if i > 0
                    base_dir = r_dir[0..i-1]
                  else
                    base_dir = ''
                  end
                end 
                
                puts "Base-Dir: #{base_dir}"
                test.setDir base_dir
                
                item = {
                  #:url => base_url.gsub(/\/$/,'') + p['escapedPath'],
                  :url => start_path,
                  :page_info => p,
                  :file_info => nil,
                  :status => nil
                }
                
              
                @disp_queue << item                 
              
              end
              #test.replaceFileExt('')
              return valid_request
            end            
          end
        end
        nil
      end
      
    end
  end
end