module Watobo
  module Plugin
    class Sequencer
      class Element

        include Watobo::Mixins::RequestParser
        include Watobo::Constants

        attr :name
        attr_accessor :request, :pre_script, :post_script, :enabled, :egress_handler, :egress_handler_enabled

        # we need this for RequestParser mixin
        def to_s
          puts @request.inspect
          @request
        end

        def to_h
          h = {}
          h[:name] = @name
          h[:request] = @request
          h[:pre_script] = @pre_script
          h[:post_script] = @post_script
          h[:enabled] = @enabled
          h[:egress_handler] = @egress_handler
          h[:egress_handler_enabled] = @egress_handler_enabled
          h
        end

        def run_pre(request)
          pre_lambda = eval(pre_script)
          if pre_lambda.arity == 1
            pre_lambda.call request
          else
            pre_lambda.call
          end
        end

        def run_post(request, response)
          post_lambda = eval(post_script)
          if post_lambda.arity == 1
            post_lambda.call response
          elsif post_lambda.arity == 2
            post_lambda.call request, response
          else
            post_lambda.call
          end
        end

        def enabled?
          @enabled
        end

        def enable
          @enabled = true
        end

        def disable
          @enabled = false
        end

        def initialize(sequence, prefs)
          @request = nil
          @pre_script = nil
          @post_script = nil
          @egress_handler = nil
          @enabled = true
          @sequence = sequence
          @sender = Watobo::Session.new

          %w( name request pre_script post_script enabled egress_handler egress_handler_enabled ).each do |e|
            instance_variable_set("@#{e}", prefs[e.to_sym]) if prefs[e.to_sym]
          end
        end

        def exec(nprefs = {}, &block)
          begin
            request = to_request

            prefs = Watobo::Conf::Scanner.to_h
            #prefs = { logging: false }

            prefs.update nprefs

            unless pre_script.nil? or pre_script.empty?
              # f = eval(element.pre_script)
              # f.call(request) if f.respond_to? :call
              run_pre(request)
            end

            yield request if block_given?

            if egress_handler.respond_to? :length
              unless egress_handler.empty?
                prefs[:egress_handler] = egress_handler
              end
            end

            test_req, response = @sender.doRequest(request, prefs)

            unless post_script.nil? or post_script.empty?
              # f = eval(element.post_script)
              # f.call(response) if f.respond_to? :call
              run_post(request, response)
            end

            chat = Watobo::Chat.new(test_req, response, :source => CHAT_SOURCE_SEQUENCER, :run_passive_checks => false)

            Watobo::Chats.add(chat) if prefs[:logging] == true
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            binding.pry if $DEBUG
          end
          return nil
        end

        def method_missing?(name, *args, &block)
          v = @sequence.vars[name.downcase]
          return v if v
          super
        end
      end
    end
  end
end