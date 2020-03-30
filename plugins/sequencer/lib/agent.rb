# @private 
module Watobo#:nodoc: all
  module Plugin
    class Sequencer
      class Agent < Watobo::Session
         def initialize()

            super(@request.object_id,  Watobo::Conf::Scanner.to_h )

         end

         # do_request
         # input:
         #        - request
         #        - prefs
         # returns: chat
         def do_request(request, prefs={})
           begin
              test_req, test_resp = self.doRequest(request, prefs)
              return Watobo::Chat.new(test_req, test_resp)
           rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
           end
           return nil
         end
      end
      
    end
  end
end