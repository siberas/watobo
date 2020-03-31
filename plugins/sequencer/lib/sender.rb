# @private 
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Sender < Watobo::Session
        attr_accessor :logging

        def initialize()
          @logging = false

          super(self.object_id, Watobo::Conf::Scanner.to_h)

        end

        def run_sequence(sequence)
          if sequence.nil?
            puts "!No Sequence active!"
            return false
          end

          puts "+ running sequence"
          sequence.each do |e|
            if e.enabled?
              puts e.name

              do_request(e)
            end
          end
        end

        # do_request
        # input:
        #        - request
        #        - prefs
        # returns: chat
        def do_request(element, prefs = {})
          begin
            request = element.to_request

            test_req, test_resp = self.doRequest(request, prefs)
            unless element.post_script.nil? or element.post_script.empty?
              f = eval(element.post_script)
              f.call(test_resp)
            end

            chat = Watobo::Chat.new(test_req, test_resp, :source => CHAT_SOURCE_MANUAL, :run_passive_checks => false)

            Watobo::Chats.add(chat) if logging == true
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