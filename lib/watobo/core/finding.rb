# @private 
module Watobo#:nodoc: all
  class Finding < Conversation

    @@numFindings = 0
    @@max_id = 0

    @@lock = Mutex.new

    attr :details
    attr :request
    attr :response
    def resetCounters()
      @@numFindings = 0
      @@max_id = 0
    end

    def id()
      @details[:id]
    end

    def false_positive?
      @details[:false_positive]
    end

    def set_false_positive
      @details[:false_positive] = true
    end

    def unset_false_positive
      @details[:false_positive] = false
    end
    
    def method_missing(name, *args, &block)
      if @details.has_key? name
        return @details[name]
      end
      super
    end
    
    def to_h
      h = { :details => @details }
      h[:request] = @request.to_a
      h[:response] = @response.to_a
      h
    end

    def initialize(request, response, details = {})
      super(request, response)
      @details = {
        :id => -1,
        :comment => '',
        :false_positive => false    # FalsePositive
      }

      @details.update details if details.is_a? Hash

      @@lock.synchronize{
      # enter critical section here ???
        if @details[:id] > 0 and @details[:id] > @@max_id
          @@max_id = @details[:id]
        elsif @details[:id] < 0
          @@max_id += 1
          @details[:id] = @@max_id
        end
        @@numFindings += 1

      }
    #  extendRequest()
    #  extendResponse()

    end

  end
end