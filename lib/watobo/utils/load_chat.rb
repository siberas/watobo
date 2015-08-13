# @private 
module Watobo#:nodoc: all
  module Utils
    
    def Utils.loadChatMarshal(file)
      begin
        request = []
        response = []
        if File.exists?(file) then
          puts "LoadChatMarshal: #{file}" if $DEBUG 
          settings = {}
          File.open(file,"rb") { |fh|
             settings = Marshal::load(fh.read)
             request = settings[:request]
             response = settings[:response]
             settings.delete(:response)
             settings.delete(:request)
             
            }
          
          
          chat = Watobo::Chat.new(request, response, settings)
          chat.file = file
          
          return chat
          
        else
          puts "* file #{file} not found"
          return nil
        end
      rescue Psych::SyntaxError
        puts "!!! Malformed File #{file}"
      rescue => bang
        puts "! could not load chat from file #{file}"
        puts bang
        puts bang.backtrace
        #puts cdata
        #puts bang
        #puts bang.backtrace if $DEBUG
      end
    end
    
    # loadChat returns a chat object imported from a yaml file
    def Utils.loadChatYAML(file)
      begin
        if File.exists?(file) then
          puts "LoadChatYAML: #{file}" if $DEBUG 
          cdata  = YAML.load(File.open(file,"rb").read)
          return nil unless cdata
          # need to restore CRLF
          cdata[:request].map!{|l| 
            if l =~ /^\"/ then
              x = secure_eval(l)
            else
              x = l.strip + "\r\n"
              x = l if l == cdata[:request].last
            end
            
            x
          }
          
          cdata[:response].map!{|l| 
            if l =~ /^\"/ then
              x = secure_eval(l)
            else
              x = l.strip + "\r\n"
              x = l if l == cdata[:response].last
            end   
            
            x
          }
          # puts cdata
          # puts cdata.class
          
          settings = Hash.new
          settings.update cdata
          settings.delete(:response)
          settings.delete(:request)
          
          chat = Watobo::Chat.new(cdata[:request], cdata[:response], settings)
          chat.file = file
          
          return chat
          
        else
          puts "* file #{file} not found"
          return nil
        end
      rescue Psych::SyntaxError
        puts "!!! Malformed File #{file}"
      rescue => bang
        puts "! could not load chat from file #{file}"
        #puts cdata
        #puts bang
        #puts bang.backtrace if $DEBUG
      end
    end
    
    
    def Utils.loadFindingMarshal(file)
      puts "LoadFindingMarshal: #{file}" if $DEBUG 
      if File.exists?(file) then
        begin
        fdata  = nil
        
        File.open(file,"rb") {|f|
          fdata = Marshal::load(f.read)        
        }
        
        finding = Watobo::Finding.new(fdata[:request], fdata[:response], fdata[:details])
        
        return finding
      rescue => bang
        puts bang
        puts "could not load finding #{file}"
        return nil
        end
      else
        #   puts "* file #{file} not found"
        return nil
      end
    end
    
    def Utils.loadFindingYAML(file)
      puts "LoadFindingYAML: #{file}" if $DEBUG 
      if File.exists?(file) then
        begin
        fdata  = YAML.load(File.open(file,"rb").read)
        # need to restore CRLF
        return nil unless fdata
        fdata[:request].map!{|l| 
          if l =~ /^\"/ then
            x = secure_eval(l)
          else
            x = l.strip + "\r\n"
            x = l if l == fdata[:request].last
          end
          x
        }
        
        fdata[:response].map!{|l|
          if l =~ /^\"/ then
            x = secure_eval(l)
          else
            x = l.strip + "\r\n"
            x = l if l == fdata[:response].last
          end
          x
        }
        finding = Watobo::Finding.new(fdata[:request], fdata[:response], fdata[:details])
        
        return finding
      rescue => bang
        puts bang
        puts "could not load finding #{file}"
        return nil
        end
      else
        #   puts "* file #{file} not found"
        return nil
      end
    end
    
    def Utils.loadChat(path, id, request_pattern, response_pattern)
      chat = nil
      req_file = File.join(path, "#{id}#{request_pattern}")
      res_file = File.join(path, "#{id}#{response_pattern}")
      #   puts "* load chat (request): #{req_file}"
      #   puts "* load chat (response): #{res_file}"
      request = []
      if File.exists?(req_file) then
        fh = File.open(req_file,"rb")
        fh.each do |line|  
          request.push line
        end
      else
        # puts "!! File not found (#{req_file})"
        return nil,nil
      end
      
      response = []
      # print "."
      # first only read header as array
      content_length = 0
      response_is_gzipped = false
      content_is_chunked = false
      max_response_size = 50000
      
      if File.exists?(res_file) then
        begin
          
          resFH = open(res_file, "rb")
          
          loop do
            l = resFH.readline
            if l =~ /Content-Length.* (\d*)/ then
              content_length = $1.to_i
              #puts "Content-Length is #{content_length}"
            end
            if l =~ /Content-Encoding.*gzip/ then
              response_is_gzipped = true
            end
            if l=~ /Transfer-Encoding.*chunked/i then
              content_is_chunked = true
            end
            response.push(l)
            # break if l.length < 3 # end of header
            break if l =~ /^\r\n$/ # end of header
          end    
          
          if content_is_chunked then
            # read rest of file
            response.push "\r\n"
            response.push resFH.read
            #content_length = dummy.chomp.hex
            return request, response
          end
        rescue => bang
          puts "Could not read Header from file #{res_file}"
        end
        # now read response body
        begin
          if response_is_gzipped and content_length > 0 then            
            gziped = resFH.read(content_length)
            begin
              gz = Zlib::GzipReader.new( StringIO.new( gziped ) )
              data = gz.read
              if data.length > max_response_size then
                data = data[0..max_response_size]
                puts "!!! chat file (#{res_file}: Response too long"
                # puts data
              end
              response.push data
            rescue => bang
              puts "ERROR: GZIP with file #{res_file}"
              puts bang
              #resFH.each do |l|
              #  response.push(l) if response.join.length < @max_response_size
              #end
            end
            return request, response
          end
          
          #resFH.each do |l|
          #  response.push(l) if response.join.length < max_response_size
          #end
          rest = resFH.read
          response.push(rest)
          
          return request, response
        rescue EOFError => bang
          return request, response
        rescue => bang
          puts "!!! Error: Could not read response file #{res_file}"
          puts bang
        end
        
      end
    end
    
    
  end
end
