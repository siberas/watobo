# @private 
module Watobo#:nodoc: all
  class Chat < Conversation
    attr :request
    attr :response
    attr :settings

    @@numChats = 0
    @@max_id = 0

    @@lock = Mutex.new

    public
    def resetCounters()
      @@numChats = 0
      @@max_id = 0
    end

    def tested?()
      return false unless @settings.has_key?(:tested)
      return @settings[:tested]
    end

    def tested=(truefalse)
      @settings[:tested] = truefalse
    end

    def tstart()
      @settings[:tstart]
    end

    def tstop()
      @settings[:tstop]
    end

    def id()
      @settings[:id]
    end

    def comment=(c)
      @settings[:comment] = c
    end

    def comment()
      @settings[:comment]
    end
    
    def use_ssl?
      request.proto =~ /https/
    end

    def source()
      @settings[:source]
    end
    
    def to_h
      h = {}
      h.update @settings
      h[:request] = @request.to_a
      h[:response] = @response.to_a
      h
    end


    # INITIALIZE ( request, response, prefs )
    # prefs:
    #   :source - source of request/response CHAT_SOURCE
    #   :id     - an initial id, if no id is given it will be set to the @@max_id, if id == 0 counters will be ignored.
    #   :start  - starting time of request format is Time.now.to_f
    #   :stop   - time of loading response has finished
    #   :
    def initialize(request, response, prefs = {})

      begin
        @settings = {
          :source => CHAT_SOURCE_UNDEF,
          :id => -1,
          :start => 0,
          :stop => -1,
          :comment => '',
          :tested => false
        }
        
        super(request, response)

       

        @settings.update prefs
        #  puts @settings[:id].to_s

        @@lock.synchronize{
        # enter critical section here ???
          if @settings[:id] > @@max_id
            @@max_id = @settings[:id]
          elsif @settings[:id] < 0
            @@max_id += 1
            @settings[:id] = @@max_id
          end
          @@numChats += 1
        # @comment = ''
        # leafe critical section here ???
        }

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

  end
end