require 'pry'
require_relative './evasion_base'

module Watobo
  # module for evasion functions
  # must be include in active check sub-classes - NOT inside ActiveCheck directly, because dynamic functions will not be inherited
  # to sub-classes
  # e.g.
  #     class MyCheck < ActiveCheck
  #       include Watobo::Evasions
  #
  # it will provide some functions to the class for handling  the evasion handlers
  # evasion_handlers(['slash']) do |h| puts h.name ; end
  #
  # or sort by prio ritiy:
  # evasion_handlers().sort_by{|h| h.prio }.map{|h| puts "#{h.name}: #{h.prio}" }
  #
  module Evasions

    @evasion_handlers = {}
    @evasion_enabled = true

    def self.add_handlers
      Watobo::EvasionHandlers.constants.each do |handler|
        # don''t add the base class
        next if handler.to_s =~ /EvasionHandlerBase/i
        h = Watobo::EvasionHandlers.class_eval(handler.to_s)
        @evasion_handlers[handler] = h
      end
    end

    def self.evasion_handlers
      @evasion_handlers
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

    def self.init_handlers
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

    # @param filters [Array] of Regexs for filtering evasion handlers by their name
    # @return Array of EvasionHandlers which names matched the filters
    #
    def evasion_handlers(filters=nil, &block)
      handlers = self.class.instance_variable_get(:@evasion_handlers)
      active_handlers = []

      active_filters = filters || ['.*']
      active_filters = [ active_filters] if active_filters.is_a? String

      handlers.sort_by { |h | h.prio }.each do |h|
        active_filters.each do |f|
          p = ( f == :all ? '.*' : f )
          next unless h.name =~ /#{p}/i
          active_handlers << h
          # we cannot yield to the block, because it is passed as a proc.
          # yield h if block_given?
          # instead we call the proc
          yield h if block_given?
        end
      end
      active_handlers
    end

    def evasions_OBSOLETE(request, &block)
      begin
        unless evasion_enabled?
          yield request
          return
        end

        active_handlers = evasion_handlers.values

        unless evasion_filter.empty?
          active_handlers = []
          evasion_handlers.each { |name, handler|
            evasion_filter.each do |f|
              active_handlers << handler if name =~ /#{f}/i
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
        # binding.pry
      end
    end

    # if
    def self.included(base)
      base.extend self
      base.instance_variable_set(:@evasion_handlers, evasion_handlers.values.map { |h| h.new })
      # base.const_set :Evasions, evasion_handlers

=begin
      base.define_method(:evasion_handlersXXX) do |filters = nil, &block|
        handlers = self.class.instance_variable_get(:@evasion_handlers)
        active_handlers = []

        active_filters = filters || ['.*']
        handlers.each do |h|
          active_filters.each do |f|
            next unless h.name =~ /#{f}/i
            active_handlers << h
            # we cannot yield to the block, because it is passed as a proc.
            # yield h if block_given?
            # instead we call the proc
            block.call(h) if block
          end
        end
        active_handlers
      end
=end
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

    # the Proxy is only a dummy object used by the the latter methods
    # class Proxy
    #  include Evasions
    # end

    # def self.evasions(*args, &block)
    #  Proxy.evasions(*args, &block)
    # end

    # def self.evasion_enabled?(*args, &block)
    #  Proxy.evasion_enabled?(*args, &block)
    # end

    # def self.enable_evasion(*args, &block)
    #  Proxy.enable_evasion(*args, &block)
    # end

    # def self.disable_evasion(*args, &block)
    #  Proxy.disable_evasion(*args, &block)
    # end
  end
end

Watobo::Evasions.init_handlers

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