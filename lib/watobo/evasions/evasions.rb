require 'pry'
module Watobo
  # module for evasion functions
  # must be include in active check sub-classes - NOT inside ActiveCheck directly, because dynamic functions will not be inherited
  # to sub-classes
  # e.g.
  #     class MyCheck < ActiveCheck
  #       include Watobo::Evasions
  #
  #
  module Evasions

    @evasion_handlers = {}
    @evasion_enabled = true

    def self.add_handlers
      Watobo::EvasionHandler.constants.each do |handler|
        h = Watobo::EvasionHandler.class_eval(handler.to_s)
        @evasion_handlers[handler] = h.new
      end
    end

    def self.dryrun(request)
      stats = {}
      @evasion_handlers.each do |name, handler|
        handler.run(request) { |r|
          stats[name] ||= 0
          stats[name] += 1
        }
      end
      stats
    end

    def self.load_handlers
      puts "+ [#{self}] load evasion handlers ..."
      Dir.glob("#{File.dirname(__FILE__)}/buildin/*.rb").map do |f|
        print '+' if $DEBUG
        Kernel.load f
      end

      add_handlers
    end

    def self.list(&block)
      @evasion_handlers.each_key do |name|

        yield name.to_s if block_given?
      end
      @evasion_handlers.map { |k, v| k.to_s }
    end

    def evasion_enabled?
      @evasion_enabled ||= true
      @evasion_enabled
    end

    def enable_evasion
      @evasion_enabled = true
    end

    def disable_evasion
      @evasion_enabled = false
    end

    # @param filter [Array] of regexes
    def evasion_filter=(filter)
      @evasion_filter = filter
    end

    def evasion_filter
      @evasion_filter ||= []
      @evasion_filter
    end

    def evasions(request, &block)
      begin
        unless evasion_enabled?
          yield request
          return
        end

        active_handlers = evasion_handlers.values
        unless evasion_filter.empty?
          active_handlers = []
          evasion_handlers.each { |n, h|
            evasion_filter.each do |f|
              active_handlers << h if n =~ /#{f}/i
            end
          }
        end

        active_handlers.each do |h|

          h.run(request.clone) { |r|
            yield r
          }
        end
      rescue => bang
        puts bang
        puts bang.backtrace
        binding.pry
      end
    end

    def self.included(base)
      base.extend self
      base.instance_variable_set(:@evasion_handlers, @evasion_handlers)

      base.define_method :evasion_handlers do
        self.class.instance_variable_get("@evasion_handlers");
      end

      #base.class_eval { attr_reader :evasion_xxx }
    end

=begin
    def self.included_UNUSED(base)
      base.extend ClassMethods
      # puts "\n --- Evasion Included"
      #puts base
      #puts @evasion_handlers
      #binding.pry
      base.instance_variable_set(:@evasion_handlers, @evasion_handlers)
      base.instance_variable_set(:@evasion_enabled, true)
      base.instance_variable_set(:@evasion_filter, [])


      base.define_method :evasion_enabled? do
        self.class.send(:evasion_enabled?);
      end
      base.define_method :enable_evasion do
        self.class.send(:enable_evasion);
      end

      base.define_singleton_method("my_singleton_method4") do
        "hello from my_singleton_method4";
      end

      base.define_method :disable_evasion do
        self.class.send(:disable_evasion);
      end

      base.define_method :evasion_handlers do
        self.class.instance_variable_get("@evasion_handlers");
      end

      base.class_eval { attr_reader :evasion_filter }

      base.define_method :evasion_filter= do |filter|
        self.instance_variable_set("@evasion_filter", filter)
      end

      base.define_method :evasions do |request, &block|
        self.class.send(:evasions, request, &block)
      end

    end
=end

    class Proxy
      include Evasions
    end

    def self.evasions(*args, &block)
      Proxy.evasions(*args, &block)
    end

    def self.evasion_enabled?(*args, &block)
      Proxy.evasion_enabled?(*args, &block)
    end

    def self.enable_evasion(*args, &block)
      Proxy.enable_evasion(*args, &block)
    end

    def self.disable_evasion(*args, &block)
      Proxy.disable_evasion(*args, &block)
    end
  end
end

Watobo::Evasions.load_handlers

if $0 == __FILE__
  require 'devenv'
  require 'watobo'
  require 'pry'

  rstr = <<EOF
GET https://no.existing.host/path/to/success/index.jsp HTTP/1.1
Host: no.existing.host
User-Agent: Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:79.0) Gecko/20100101 Firefox/79.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Content-Length: 0
Upgrade-Insecure-Requests: 1
Connection: close
EOF


  request = Watobo::Utils.text2request rstr

  filter = ARGV

  class Dummy
    include Watobo::Evasions

    def run(request, *filter)
      count = 0
      evasions(request, *filter) do |r|
        count += 1
        puts r.to_s
      end
      count
    end
  end

  class Dummy2 < Dummy

  end

  class Second < Dummy
    include Watobo::Evasions

  end

  dummy = Dummy.new
  second = Second.new

  binding.pry

  dummy.run request, filter
  puts Watobo::Evasions.dryrun(request).to_json
end