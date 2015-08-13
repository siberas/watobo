# @private 
module Watobo#:nodoc: all
  module Plugin
    class CQ5
      class Agent < Watobo::Session
         def initialize(base_request, in_queue, out_queue )
            @work_queue = in_queue
            @disp_queue = out_queue
            @request = base_request
            
            
            super(@request.object_id,  Watobo::Conf::Scanner.to_h )

         end
         
         def stop
           @agent_thread.kill
         end
         
         def run
           return nil if @work_queue.nil? or @disp_queue.nil?
           
           @agent_thread = Thread.new(){
             puts "#{self} running ..." 
             loop do
             begin
              
               item = @work_queue.deq
               # not interested in jcr:content ... skip ... 
               next if item[:url] =~ /jcr%3acontent$/
              
               get_pages item
               file_info item
               
             rescue => bang
               puts bang
               puts bang.backtrace
               exit
             end
             end
           }
           @agent_thread
         end
         
         def get_pages(item)           
           test = @request.copy
          # puts item
           url = item[:url].gsub(/\/$/,'') + '/.pages.json'
           test.replaceURL( url )
           
           request, response = sendRequest test
           
           return false unless response.respond_to? :status
           item[:pages_status] = response.status
          # @disp_queue << item
             
                  
           if response.content_type =~ /json/i
             begin
             ntpages = JSON.parse response.body.to_s
             
             if ntpages['pages']
                            
              ntpages['pages'].each do |p|
                #unless @use_relative_path
                ep = p['escapedPath']
                next if ep.nil?
                next if ep.empty?
                 
                purl = ''
               
                purl = @request.url.to_s.gsub(/\/$/, '') + p['escapedPath']
                puts "+ #{purl}"
                
                next if purl.empty?
                
                item = {
                  :url => purl,
                  :page_info => p,
                  :file_info => nil,
                  :status => nil
                }
                                 
                @disp_queue << item
               end              
             end      
           
             rescue => bang
                puts bang
                puts ntpages
                puts "---"
              end   
           end
           #puts response.body.to_s 
           true
         end
         
         def file_info(item)
           #url = item[:url]
           #@request.replaceURL "#{url}/.json"
           test = @request.copy
           test.set_file_extension "json"
          # puts "\n>> #{@request.url}"
           request, response = sendRequest test
           
           return false unless response.respond_to? :status
           item[:info_status] = response.status
           
           if response.content_type =~ /json/i
             info = JSON.parse response.body.to_s
             item[:file_info] = info
           end
           #@disp_queue << item
           true
         end

         def sendRequest(request, prefs={})
           begin
              test_req, test_resp = self.doRequest(request, prefs)
              return test_req, test_resp
           rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
           end
           return nil, nil            
         end
      end
      
    end
  end
end