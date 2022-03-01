# @private 
module Watobo#:nodoc: all
  class Finding < Conversation

    @@numFindings = 0
    @@max_id = 0

    @@lock = Mutex.new

    attr :details
    attr :request
    attr :response
    def self.resetCounters()
      @@numFindings = 0
      @@max_id = 0
    end

    def id()
      @details[:id]
    end

    # return severity score 0 (none) - 10 (critical)
    def severity
      return 0.0 unless !!@details[:type]
      return 0.0 unless @details[:type] == Watobo::Constants::FINDING_TYPE_VULN
      score = case @details[:rating]
              when Watobo::Constants::VULN_RATING_CRITICAL
                10.0
              when Watobo::Constants::VULN_RATING_HIGH
                9.0
              when Watobo::Constants::VULN_RATING_MEDIUM
                7.0
              when Watobo::Constants::VULN_RATING_LOW
                3.0
              else
                0.0
              end
      score
    end

    def type_str
      s = case @details[:type]
          when FINDING_TYPE_INFO
            'info'
          when FINDING_TYPE_HINT
            'hint'
          when FINDING_TYPE_VULN
            'vulnerability'
          else
            'n/a'
          end
      s
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