# @private
=begin
   https://github.com/GDSSecurity/GWT-Penetration-Testing-Toolset/blob/master/gwtparse/GWTParser.py
=end
module Watobo #:nodoc: all
  module HTTPData

    class GWTRequest

      def initialize(gwtserial)
        fields = gwtserial.split('|')
        puts fields.length

        @version = fields[0]
        @flags = fields[1]
        @str_table_length = fields[2].to_i
        @string_table = []
        @string_table.concat fields[3..3+@str_table_length]
        puts 'String Table >>>'
        @string_table.each_with_index do |s, i|
          puts "[#{i+1}] #{s}"
        end
      end


    end

    class GWTrpc

      module Mixin
        def gwtrpc
          @gwtrpc ||= Watobo::HTTPData::GWTrpc.new(self)
        end
      end

      def to_s
        s = @root.body.to_s
      end


      STRING_OBJECT = "java.lang.String"
      INTEGER_OBJECT = "java.lang.Integer"
      DOUBLE_OBJECT = "java.lang.Double"
      FLOAT_OBJECT = "java.lang.Float"
      BYTE_OBJECT = "java.lang.Byte"
      BOOLEAN_OBJECT = "java.lang.Boolean"
      SHORT_OBJECT = "java.lang.Short"
      CHAR_OBJECT = "java.lang.Char"
      LONG_OBJECT = "java.lang.Long"

      PRIMITIVES_WRAPPER = [STRING_OBJECT, INTEGER_OBJECT, DOUBLE_OBJECT, FLOAT_OBJECT, BYTE_OBJECT, BOOLEAN_OBJECT, SHORT_OBJECT, CHAR_OBJECT]

      LONG = "J"
      DOUBLE = "D"
      FLOAT = "F"
      INT = "I"
      BYTE = "B"
      SHORT = "S"
      BOOLEAN = "Z"
      CHAR = "C"

      PRIMITIVES = ["J", "D", "F", "I", "B", "S", "Z", "C"]
      NUMERICS = [INT, CHAR, BOOLEAN, BYTE, SHORT, INTEGER_OBJECT, CHAR_OBJECT, BYTE_OBJECT, BOOLEAN_OBJECT, SHORT_OBJECT]

      ARRAYLIST = "java.util.ArrayList"
      LINKEDLIST = "java.util.LinkedList"
      VECTOR = "java.util.Vector"

      ListTypes = [ARRAYLIST, LINKEDLIST, VECTOR]

      def parameters(&block)

        return nil unless @root.has_body?
        return nil unless @root.is_gwtrpc?

        parms = parse(@root.body)

        return parms
      end

      def initialize(root)
        @root = root


      end

      private

      def parse(grs)


        []
      end

    end
  end
end

if $0 == __FILE__

# 7|0|7|https://172.23.229.230:2443/swp/login/|83FA4D6C820A43D9AF64DED640794852|com.swift.sagadmin.swiftnetusers.SwiftNetUsersLocal|list|java.lang.String/2004016611|1|2|3|4|2|5|6|7|6|0|
#
  class RequestDummy
    include Watobo::HTTPData::GWTrpc::Mixin

    def has_body?
      true
    end

    def is_gwtrpc?
      true
    end

    def body
      @body
    end

    def initialize(body)
      @body = body
    end
  end

  Watobo::HTTPData::GWTRequest.new(ARGV[0])
  exit
  dummy = RequestDummy.new(ARGV[0])

  dummy.gwtrpc.parameters.each do |p|

  end

end
