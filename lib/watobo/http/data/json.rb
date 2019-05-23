# @private
module Watobo #:nodoc: all
  module HTTPData
    class Json

      module Mixin
        def json
          @json ||= Watobo::HTTP::Json.new(self)
        end
      end

      def to_s
        s = @root.body.to_s
      end

      def clear
        @root.set_body ''
      end

      #
      def set(parm)
        return false unless parm.location == :json
        index = parm.name
        ref = @mapping[index]
        hash = JSON.parse(@root.body.strip)
        eval("hash#{ref}=#{parm.value}")


        @root.set_body doc.to_s

      end

      def has_parm?(parm_name)
        false
      end

      def parameters(&block)
        params = []

        return params unless @root.is_json?

        hash = JSON.parse(@root.body.strip)
        parameters = parse(hash)


        return params
      end

      def initialize(root)
        @root = root
        @mapping = nil

      end

      private

      def index_name(name, index)
        xn = name.scan(/\['[^\[]*'\]/).last
        xn.gsub!(/[#{Regexp.quote("'[]")}]/,'')
        "#{xn}_#{index}"
      end

      # parse the hash structure and generate indexed param names
      def parse(hash, &block)
        return nil unless @root.has_body?
        parms = []
        @mapping = {}
        begin
          iterate(nil, hash, 0) {|k, v|

            mname = index_name(k, parms.length)
            puts "[#{mname}] --> #{k} : #{v}"
            @mapping[mname] = k
            parms << JSONParameter.new(:name => mname, :value => v)
          }

        rescue => bang
          puts bang
          puts bang.backtrace
        end
        parms
      end

      def iterate(root, object, index = 0, &block)
        index += 1
        base = root.nil? ? '' : root

        if object.is_a?(Hash)
          object.each do |k, v|
            new_base = "#{base}['#{k}']"
            if v.is_a?(Hash)
              yield [new_base, v] if block_given?
              iterate(new_base, v, index, &block)
            elsif v.is_a?(Array)
              yield [new_base, v] if block_given?
              iterate(new_base, v, index, &block)
            else
              yield [new_base, v] if block_given?
            end
          end
        elsif object.is_a?(Array)
          object.each_with_index do |v, i|
            new_base = "#{base}[#{i}]"
            yield [new_base, v] if block_given?
            iterate(new_base, v, index, &block)
          end
        else
          yield [base, object] if block_given?
        end
      end

    end
  end
end

if __FILE__ == $0
  require 'devenv'
  require 'watobo'

  require 'pry'

  class RootDummy
    def has_body?
      true
    end

    def is_json?
      true
    end

    def body
      {aaa: '3xA', bbb: 'outer', ccc: [yyy: {xxx: '3xX', bbb: 'nested'}]}.to_json
    end


  end

  root = RootDummy.new
  json = Watobo::HTTP::Json.new(root)

  puts json.to_s

  binding.pry

  exit

end