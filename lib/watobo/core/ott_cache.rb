# @private 
module Watobo#:nodoc: all
  class OTTCache
    @otts = {}
    @otts_lock = Mutex.new
    
    attr :tokens
    
    def initialize()
      @tokens = {}
      @tokens_lock = Mutex.new
    end
    
    def self.acquire(request)
      urh = request.uniq_hash
      unless @otts.has_key? urh
        @otts[urh] = OTTCache.new()
      end
      @otts[urh]
    end
    
    
    def self.patterns(&block)
   
        Watobo::Conf::OttCache.patterns.each do |p|
          yield p if block_given?
        end
        YAML.load(YAML.dump(Watobo::Conf::OttCache.patterns))
   
    end
    
      
    def update_tokens(response)
        
        begin
          #   site = request.site
          @tokens_lock.synchronize do
            response.each do |line|
              # puts line
              self.class.patterns do |pat|
                puts pat if $DEBUG
                if line =~ /#{pat}/i then
                  token_key = Regexp.quote($1.upcase)
                  token_value = $2
                  #print "U"
                    puts "GOT NEW TOKEN (#{token_key}): #{token_value}" if $DEBUG
                  #   @session[:valid_csrf_tokens][site] = Hash.new if @session[:valid_csrf_tokens][site].nil?
                  #   @session[:valid_csrf_tokens][site][token_key] = token_value
                  @tokens[token_key] = token_value
                end
              end

            end
          end
        rescue => bang
          puts bang
          if $DEBUG
          puts bang.backtrace 
          puts "= Request"
          puts request 
          puts "= Response"
          puts response
          puts "==="
          end

        end
        # }
      end
    
    # target could be a Watobo::Chat or a Watobo::Request object
    def self.set_chat_ids(target, ott_chat_ids)
      r = target
      r = target.request if target.respond_to? :request
      @otts_lock.synchronize do
        Watobo::Conf::OttCache.request_ids[r.uniq_hash] = ott_chat_ids
      end
    end
    
    def self.requests(target, &block)
      ott_requests = []
      return ott_requests if target.nil?
      self.chats(target) do |chat|
        ott_request = chat.copyRequest
        ott_requests << ott_request
      end
      ott_requests
    end
    
    # returns an array of Watobo::Requests which are necessary 
    # to update the token
    def self.chats(target, &block)
      ott_chats = []
      return ott_chats if target.nil?
      request = target.respond_to?(:request) ? target.request : target
      urh = request.uniq_hash
      
      @otts_lock.synchronize do
        return ott_chats unless Watobo::Conf::OttCache.request_ids.has_key? urh
        Watobo::Conf::OttCache.request_ids[urh].each do |id|
         #puts "* [OTT] get chat for id #{id}"
          chat = Watobo::Chats.get_by_id(id)
          unless chat.nil?  
          #ottr = chat.copyRequest
          ott_chats << chat 
          yield chat if block_given?
          end
        end
      end
      ott_chats
    end
    
    
    # update tokens for a specific request
    def update_request(request)     
      #urh = target_request.uniq_hash 
      #return false unless @tokens.has_key? urh       
        @tokens_lock.synchronize do       
          request.map!{ |line|
            res = line
            self.class.patterns do |pat|
              begin
                if line =~ /#{pat}/i then
                  key = Regexp.quote($1.upcase)
                  old_value = $2
                  if @tokens.has_key?(key) then
                    res = line.gsub!(/#{Regexp.quote(old_value)}/, @tokens[key])
                    if res.nil? then
                      res = line
                      puts "!!!could not update token (#{key})"
                    end
                  else
                    if $DEBUG
                      puts "[OTT] nothing to update?"
                      puts @tokens.to_yaml
                      puts request
                    end 
                  end
                end
              rescue => bang
                puts bang
                puts bang.backtrace if $DEBUG
                # puts @session.to_yaml
              end
            end
            res
          }
        end
        # end
      end
  end
end