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
        # ignore 'clear' because this will destroy mapping
      end

      #
      def set(parm)
        return false unless parm.location == :json

        hash = JSON.parse(@root.body.strip)
        # refresh mapping by parsing
        parse(hash)

        # TODO: add posibility to add new parameters
        # return if parameter does not have an id. This might be the case if the
        # parameter has been created manually, to be added as a new parameter.
        # non existing parameters don't have an id
        return false if parm.id.nil?

        index = parm.id


        ref = @mapping[index]
        # return immediatly if no reference can be found
        # this might happen if structurs have been overridden before
        return false if ref.nil?
        hash = JSON.parse(@root.body.strip)

        #puts "[Mapping] #{parm.name} -> #{index} --> #{ref}"
        new_val = parm.value
        #  puts "[EVAL] hash#{ref}=#{new_val}"
        eval("hash#{ref}=new_val")

        @root.set_body hash.to_json

      end

      def has_parm?(parm_name)
        false
      end

      # @input opts [*SYM]
      #    supported values:
      #                       :skip_structures - do not return structure types like Array of Hash
      #
      def parameters(&block)

        return [] unless @root.is_json?
        return [] unless @root.has_body?

        hash = JSON.parse(@root.body.strip)
        ps = parse(hash)

        return ps
      end

      def initialize(root)
        @root = root
        @mapping = nil

      end

      private

      def index_name(name, index)
        xn = name.scan(/\['[^\[]*'\]/).last
        xn.gsub!(/[#{Regexp.quote("'[]")}]/, '') unless xn.nil?
        "#{xn}_#{index}"
      end

      # parse the hash structure and generate indexed param names
      def parse(hash, &block)
        return nil unless @root.has_body?
        parms = []
        @mapping = {}
        begin
          iterate(nil, hash, 0) {|p|
            mname = index_name(p[:name], parms.length)
            p[:id] = Digest::MD5.hexdigest(p[:name])
            #puts "[#{mname}] --> #{p[:name]} : #{p[:value]}"
            @mapping[p[:id]] = p[:name]
            parms << JSONParameter.new(p)
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
              p = {name: new_base, value: v, type: :HASH}
              yield p if block_given?
              iterate(new_base, v, index, &block)
            elsif v.is_a?(Array)
              p = {name: new_base, value: v, type: :ARRAY}
              yield p if block_given?
              iterate(new_base, v, index, &block)
            else
              p = {name: new_base, value: v, type: v.class.to_s.upcase.to_sym}
              yield p if block_given?
            end
          end
        elsif object.is_a?(Array)
          object.each_with_index do |v, i|
            new_base = "#{base}[#{i}]"
            #yield [new_base, v] if block_given?
            p = {name: new_base, value: v, type: :ARRAY}
            yield p if block_given?
            iterate(new_base, v, index, &block)
          end
        else
          #yield [base, object] if block_given?
          p = {name: base, value: object, type: object.class.to_s.upcase.to_sym}
          yield p if block_given?
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
  json = Watobo::HTTPData::Json.new(root)

  puts json.to_s

  binding.pry

  exit

end