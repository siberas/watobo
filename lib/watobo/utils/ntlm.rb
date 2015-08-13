# encoding: UTF-8
#
# = net/ntlm.rb
#
# An NTLM Authentication Library for Ruby
#
# This code is a derivative of "dbf2.rb" written by yrock
# and Minero Aoki. You can find original code here:
# http://jp.rubyist.net/magazine/?0013-CodeReview
# -------------------------------------------------------------
# Copyright (c) 2005,2006 yrock
#
# This program is free software.
# You can distribute/modify this program under the terms of the
# Ruby License.
#
# 2006-02-11 refactored by Minero Aoki
# -------------------------------------------------------------
#
# All protocol information used to write this code stems from
# "The NTLM Authentication Protocol" by Eric Glass. The author
# would thank to him for this tremendous work and making it
# available on the net.
# http://davenport.sourceforge.net/ntlm.html
# -------------------------------------------------------------
# Copyright (c) 2003 Eric Glass
#
# Permission to use, copy, modify, and distribute this document
# for any purpose and without any fee is hereby granted,
# provided that the above copyright notice and this list of
# conditions appear in all copies.
# -------------------------------------------------------------
#
# The author also looked Mozilla-Firefox-1.0.7 source code,
# namely, security/manager/ssl/src/nsNTLMAuthModule.cpp and
# Jonathan Bastien-Filiatrault's libntlm-ruby.
# "http://x2a.org/websvn/filedetails.php?
# repname=libntlm-ruby&path=%2Ftrunk%2Fntlm.rb&sc=1"
# The latter has a minor bug in its separate_keys function.
# The third key has to begin from the 14th character of the
# input string instead of 13th:)
#--
# $Id: ntlm.rb,v 1.1 2006/10/05 01:36:52 koheik Exp $
#++



module Watobo
  module NTLM
    # @private
    module VERSION
      MAJOR = 0
      MINOR = 3
      TINY  = 4
      STRING = [MAJOR, MINOR, TINY].join('.')
    end

    SSP_SIGN = "NTLMSSP\0"
    BLOB_SIGN = 0x00000101
    LM_MAGIC = "KGS!@\#$%"
    TIME_OFFSET = 11644473600
    MAX64 = 0xffffffffffffffff

    FLAGS = {
      :UNICODE              => 0x00000001,
      :OEM                  => 0x00000002,
      :REQUEST_TARGET       => 0x00000004,
      :MBZ9                 => 0x00000008,
      :SIGN                 => 0x00000010,
      :SEAL                 => 0x00000020,
      :NEG_DATAGRAM         => 0x00000040,
      :NETWARE              => 0x00000100,
      :NTLM                 => 0x00000200,
      :NEG_NT_ONLY          => 0x00000400,
      :MBZ7                 => 0x00000800,
      :DOMAIN_SUPPLIED      => 0x00001000,
      :WORKSTATION_SUPPLIED => 0x00002000,
      :LOCAL_CALL           => 0x00004000,
      :ALWAYS_SIGN          => 0x00008000,
      :TARGET_TYPE_DOMAIN   => 0x00010000,
      :TARGET_INFO          => 0x00800000,
      :NTLM2_KEY            => 0x00080000,
      :KEY128               => 0x20000000,
      :KEY56                => 0x80000000
    }.freeze

    FLAG_KEYS = FLAGS.keys.sort{|a, b| FLAGS[a] <=> FLAGS[b] }

    DEFAULT_FLAGS = {
      :TYPE1 => FLAGS[:UNICODE] | FLAGS[:OEM] | FLAGS[:REQUEST_TARGET] | FLAGS[:NTLM] | FLAGS[:ALWAYS_SIGN] | FLAGS[:NTLM2_KEY],
      :TYPE2 => FLAGS[:UNICODE],
      :TYPE3 => FLAGS[:UNICODE] | FLAGS[:REQUEST_TARGET] | FLAGS[:NTLM] | FLAGS[:ALWAYS_SIGN] | FLAGS[:NTLM2_KEY]
    }

    class EncodeUtil
      if RUBY_VERSION == "1.8.7"
        require "kconv"

        # Decode a UTF16 string to a ASCII string
        # @param [String] str The string to convert
        def self.decode_utf16le(str)
          Kconv.kconv(swap16(str), Kconv::ASCII, Kconv::UTF16)
        end

        # Encodes a ASCII string to a UTF16 string
        # @param [String] str The string to convert
        def self.encode_utf16le(str)
          swap16(Kconv.kconv(str, Kconv::UTF16, Kconv::ASCII))
        end

        # Taggle the strings endianness between big/little and little/big
        # @param [String] str The string to swap the endianness on
        def self.swap16(str)
          str.unpack("v*").pack("n*")
        end
      else # Use native 1.9 string encoding functions

        # Decode a UTF16 string to a ASCII string
        # @param [String] str The string to convert
        def self.decode_utf16le(str)
          str.encode(Encoding::UTF_8, Encoding::UTF_16LE).force_encoding('UTF-8')
        end

        # Encodes a ASCII string to a UTF16 string
        # @param [String] str The string to convert
        # @note This implementation may seem stupid but the problem is that UTF16-LE and UTF-8 are incompatiable
        #   encodings. This library uses string contatination to build the packet bytes. The end result is that
        #   you can either marshal the encodings elsewhere of simply know that each time you call encode_utf16le
        #   the function will convert the string bytes to UTF-16LE and note the encoding as UTF-8 so that byte
        #   concatination works seamlessly.
        def self.encode_utf16le(str)
          str = str.force_encoding('UTF-8') if [::Encoding::ASCII_8BIT,::Encoding::US_ASCII].include?(str.encoding)
          str.dup.force_encoding('UTF-8').encode(Encoding::UTF_16LE, Encoding::UTF_8).force_encoding('UTF-8')
        end
      end
    end

    class << self

      # Conver the value to a 64-Bit Little Endian Int
      # @param [String] val The string to convert
      def pack_int64le(val)
          [val & 0x00000000ffffffff, val >> 32].pack("V2")
      end

      # Builds an array of strings that are 7 characters long
      # @param [String] str The string to split
      # @api private
      def split7(str)
        s = str.dup
        until s.empty?
          (ret ||= []).push s.slice!(0, 7)
        end
        ret
      end

      # Not sure what this is doing
      # @param [String] str String to generate keys for
      # @api private
      def gen_keys(str)
        split7(str).map{ |str7|
          bits = split7(str7.unpack("B*")[0]).inject('')\
            {|ret, tkn| ret += tkn + (tkn.gsub('1', '').size % 2).to_s }
          [bits].pack("B*")
        }
      end

      def apply_des(plain, keys)
        dec = OpenSSL::Cipher::DES.new
        keys.map {|k|
          dec.key = k
          dec.encrypt.update(plain)
        }
      end

      # Generates a Lan Manager Hash
      # @param [String] password The password to base the hash on
      def lm_hash(password)
        keys = gen_keys password.upcase.ljust(14, "\0")
        apply_des(LM_MAGIC, keys).join
      end

      # Generate a NTLM Hash
      # @param [String] password The password to base the hash on
      # @option opt :unicode (false) Unicode encode the password
      def ntlm_hash(password, opt = {})
        pwd = password.dup
        unless opt[:unicode]
          pwd = EncodeUtil.encode_utf16le(pwd)
        end
        OpenSSL::Digest::MD4.digest pwd
      end

      # Generate a NTLMv2 Hash
      # @param [String] user The username
      # @param [String] password The password
      # @param [String] target The domain or workstaiton to authenticate to
      # @option opt :unicode (false) Unicode encode the domain
      def ntlmv2_hash(user, password, target, opt={})
        ntlmhash = ntlm_hash(password, opt)
        userdomain = (user + target).upcase
        unless opt[:unicode]
          userdomain = EncodeUtil.encode_utf16le(userdomain)
        end
        OpenSSL::HMAC.digest(OpenSSL::Digest::MD5.new, ntlmhash, userdomain)
      end

      def lm_response(arg)
        begin
          hash = arg[:lm_hash]
          chal = arg[:challenge]
        rescue
          raise ArgumentError
        end
        chal = NTLM::pack_int64le(chal) if chal.is_a?(Integer)
        keys = gen_keys hash.ljust(21, "\0")
        apply_des(chal, keys).join
      end

      def ntlm_response(arg)
        hash = arg[:ntlm_hash]
        chal = arg[:challenge]
        chal = NTLM::pack_int64le(chal) if chal.is_a?(Integer)
        keys = gen_keys hash.ljust(21, "\0")
        apply_des(chal, keys).join
      end

      def ntlmv2_response(arg, opt = {})
        begin
          key = arg[:ntlmv2_hash]
          chal = arg[:challenge]
          ti = arg[:target_info]
        rescue
          raise ArgumentError
        end
        chal = NTLM::pack_int64le(chal) if chal.is_a?(Integer)

        if opt[:client_challenge]
          cc  = opt[:client_challenge]
        else
          cc = rand(MAX64)
        end
        cc = NTLM::pack_int64le(cc) if cc.is_a?(Integer)

        if opt[:timestamp]
          ts = opt[:timestamp]
        else
          ts = Time.now.to_i
        end
        # epoch -> milsec from Jan 1, 1601
        ts = 10000000 * (ts + TIME_OFFSET)

        blob = Blob.new
        blob.timestamp = ts
        blob.challenge = cc
        blob.target_info = ti

        bb = blob.serialize
        OpenSSL::HMAC.digest(OpenSSL::Digest::MD5.new, key, chal + bb) + bb
      end

      def lmv2_response(arg, opt = {})
        key = arg[:ntlmv2_hash]
        chal = arg[:challenge]

        chal = NTLM::pack_int64le(chal) if chal.is_a?(Integer)

        if opt[:client_challenge]
          cc  = opt[:client_challenge]
        else
          cc = rand(MAX64)
        end
        cc = NTLM::pack_int64le(cc) if cc.is_a?(Integer)

        OpenSSL::HMAC.digest(OpenSSL::Digest::MD5.new, key, chal + cc) + cc
      end

      def ntlm2_session(arg, opt = {})
        begin
          passwd_hash = arg[:ntlm_hash]
          chal = arg[:challenge]
        rescue
          raise ArgumentError
        end

        if opt[:client_challenge]
          cc  = opt[:client_challenge]
        else
          cc = rand(MAX64)
        end
        cc = NTLM::pack_int64le(cc) if cc.is_a?(Integer)

        keys = gen_keys passwd_hash.ljust(21, "\0")
        session_hash = OpenSSL::Digest::MD5.digest(chal + cc).slice(0, 8)
        response = apply_des(session_hash, keys).join
        [cc.ljust(24, "\0"), response]
      end
    end


    # base classes for primitives
    # @private
    class Field
      attr_accessor :active, :value

      def initialize(opts)
        @value  = opts[:value]
        @active = opts[:active].nil? ? true : opts[:active]
      end

      def size
        @active ? @size : 0
      end
    end

    class String < Field
      def initialize(opts)
        super(opts)
        @size = opts[:size]
      end

      def parse(str, offset=0)
        if @active and str.size >= offset + @size
          @value = str[offset, @size]
          @size
        else
          0
        end
      end

      def serialize
        if @active
          @value
        else
          ""
        end
      end

      def value=(val)
        @value = val
        @size = @value.nil? ? 0 : @value.size
        @active = (@size > 0)
      end
    end

    class Int16LE < Field
      def initialize(opt)
        super(opt)
        @size = 2
      end
      def parse(str, offset=0)
        if @active and str.size >= offset + @size
          @value = str[offset, @size].unpack("v")[0]
          @size
        else
          0
        end
      end

      def serialize
        [@value].pack("v")
      end
    end

    class Int32LE < Field
      def initialize(opt)
        super(opt)
        @size = 4
      end

      def parse(str, offset=0)
        if @active and str.size >= offset + @size
          @value = str.slice(offset, @size).unpack("V")[0]
          @size
        else
          0
        end
      end

      def serialize
        [@value].pack("V") if @active
      end
    end

    class Int64LE < Field
      def initialize(opt)
        super(opt)
        @size = 8
      end

      def parse(str, offset=0)
        if @active and str.size >= offset + @size
          d, u = str.slice(offset, @size).unpack("V2")
          @value = (u * 0x100000000 + d)
          @size
        else
          0
        end
      end

      def serialize
        [@value & 0x00000000ffffffff, @value >> 32].pack("V2") if @active
      end
    end

    # base class of data structure
    class FieldSet
      class << FieldSet


        # @macro string_security_buffer
        #   @method $1
        #   @method $1=
        #   @return [String]
        def string(name, opts)
          add_field(name, String, opts)
        end

        # @macro int16le_security_buffer
        #   @method $1
        #   @method $1=
        #   @return [Int16LE]
        def int16LE(name, opts)
          add_field(name, Int16LE, opts)
        end

        # @macro int32le_security_buffer
        #   @method $1
        #   @method $1=
        #   @return [Int32LE]
        def int32LE(name, opts)
          add_field(name, Int32LE, opts)
        end

        # @macro int64le_security_buffer
        #   @method $1
        #   @method $1=
        #   @return [Int64]
        def int64LE(name, opts)
          add_field(name, Int64LE, opts)
        end

        # @macro security_buffer
        #   @method $1
        #   @method $1=
        #   @return [SecurityBuffer]
        def security_buffer(name, opts)
          add_field(name, SecurityBuffer, opts)
        end

        def prototypes
          @proto
        end

        def names
          @proto.map{|n, t, o| n}
        end

        def types
          @proto.map{|n, t, o| t}
        end

        def opts
          @proto.map{|n, t, o| o}
        end

        private

        def add_field(name, type, opts)
          (@proto ||= []).push [name, type, opts]
          define_accessor name
        end

        def define_accessor(name)
          module_eval(<<-End, __FILE__, __LINE__ + 1)
          def #{name}
            self['#{name}'].value
          end

          def #{name}=(val)
            self['#{name}'].value = val
          end
          End
        end
      end

      def initialize
        @alist = self.class.prototypes.map{ |n, t, o| [n, t.new(o)] }
      end

      def serialize
        @alist.map{|n, f| f.serialize }.join
      end

      def parse(str, offset=0)
        @alist.inject(offset){|cur, a|  cur += a[1].parse(str, cur)}
      end

      def size
        @alist.inject(0){|sum, a| sum += a[1].size}
      end

      def [](name)
        a = @alist.assoc(name.to_s.intern)
        raise ArgumentError, "no such field: #{name}" unless a
        a[1]
      end

      def []=(name, val)
        a = @alist.assoc(name.to_s.intern)
        raise ArgumentError, "no such field: #{name}" unless a
        a[1] = val
      end

      def enable(name)
        self[name].active = true
      end

      def disable(name)
        self[name].active = false
      end
    end

    class Blob < FieldSet
      int32LE    :blob_signature,   {:value => BLOB_SIGN}
      int32LE    :reserved,         {:value => 0}
      int64LE    :timestamp,      {:value => 0}
      string     :challenge,      {:value => "", :size => 8}
      int32LE    :unknown1,     {:value => 0}
      string     :target_info,      {:value => "", :size => 0}
      int32LE    :unknown2,         {:value => 0}
    end

    class SecurityBuffer < FieldSet

      int16LE   :length,        {:value => 0}
      int16LE   :allocated,     {:value => 0}
      int32LE   :offset,        {:value => 0}

      attr_accessor :active
      def initialize(opts)
        super()
        @value  = opts[:value]
        @active = opts[:active].nil? ? true : opts[:active]
        @size = 8
      end

      def parse(str, offset=0)
        if @active and str.size >= offset + @size
          super(str, offset)
          @value = str[self.offset, self.length]
          @size
        else
          0
        end
      end

      def serialize
        super if @active
      end

      def value
        @value
      end

      def value=(val)
        @value = val
        self.length = self.allocated = val.size
      end

      def data_size
        @active ? @value.size : 0
      end
    end

    # @private false
    class Message < FieldSet
      class << Message
        def parse(str)
          m = Type0.new
          m.parse(str)
          case m.type
          when 1
            t = Type1.parse(str)
          when 2
            t = Type2.parse(str)
          when 3
            t = Type3.parse(str)
          else
            raise ArgumentError, "unknown type: #{m.type}"
          end
          t
        end

        def decode64(str)
          parse(Base64.decode64(str))
        end
      end

      def has_flag?(flag)
        (self[:flag].value & FLAGS[flag]) == FLAGS[flag]
      end

      def set_flag(flag)
        self[:flag].value  |= FLAGS[flag]
      end

      def dump_flags
        FLAG_KEYS.each{ |k| print(k, "=", flag?(k), "\n") }
      end

      def serialize
        deflag
        super + security_buffers.map{|n, f| f.value}.join
      end

      def encode64
        Base64.encode64(serialize).gsub(/\n/, '')
      end

      def decode64(str)
        parse(Base64.decode64(str))
      end

      alias head_size size

      def data_size
        security_buffers.inject(0){|sum, a| sum += a[1].data_size}
      end

      def size
        head_size + data_size
      end


      def security_buffers
        @alist.find_all{|n, f| f.instance_of?(SecurityBuffer)}
      end

      def deflag
        security_buffers.inject(head_size){|cur, a|
          a[1].offset = cur
          cur += a[1].data_size
        }
      end

      def data_edge
        security_buffers.map{ |n, f| f.active ? f.offset : size}.min
      end

      # sub class definitions
      class Type0 < Message
        string        :sign,      {:size => 8, :value => SSP_SIGN}
        int32LE       :type,      {:value => 0}
      end

      # @private false
      class Type1 < Message

        string          :sign,         {:size => 8, :value => SSP_SIGN}
        int32LE         :type,         {:value => 1}
        int32LE         :flag,         {:value => DEFAULT_FLAGS[:TYPE1] }
        security_buffer :domain,       {:value => ""}
        security_buffer :workstation,  {:value => Socket.gethostname }
        string          :padding,      {:size => 0, :value => "", :active => false }

        class << Type1
          # Parses a Type 1 Message
          # @param [String] str A string containing Type 1 data
          # @return [Type1] The parsed Type 1 message
          def parse(str)
            t = new
            t.parse(str)
            t
          end
        end

        # @!visibility private
        def parse(str)
          super(str)
          enable(:domain) if has_flag?(:DOMAIN_SUPPLIED)
          enable(:workstation) if has_flag?(:WORKSTATION_SUPPLIED)
          super(str)
          if ( (len = data_edge - head_size) > 0)
            self.padding = "\0" * len
            super(str)
          end
        end
      end


      # @private false
      class Type2 < Message

        string        :sign,         {:size => 8, :value => SSP_SIGN}
        int32LE       :type,      {:value => 2}
        security_buffer   :target_name,  {:size => 0, :value => ""}
        int32LE       :flag,         {:value => DEFAULT_FLAGS[:TYPE2]}
        int64LE           :challenge,    {:value => 0}
        int64LE           :context,      {:value => 0, :active => false}
        security_buffer   :target_info,  {:value => "", :active => false}
        string        :padding,   {:size => 0, :value => "", :active => false }

        class << Type2
          # Parse a Type 2 packet
          # @param [String] str A string containing Type 2 data
          # @return [Type2]
          def parse(str)
            t = new
            t.parse(str)
            t
          end
        end

        # @!visibility private
        def parse(str)
          super(str)
          if has_flag?(:TARGET_INFO)
            enable(:context)
            enable(:target_info)
            super(str)
          end
          if ( (len = data_edge - head_size) > 0)
            self.padding = "\0" * len
            super(str)
          end
        end

        # Generates a Type 3 response based on the Type 2 Information
        # @return [Type3]
        # @option arg [String] :username The username to authenticate with
        # @option arg [String] :password The user's password
        # @option arg [String] :domain ('') The domain to authenticate to
        # @option opt [String] :workstation (Socket.gethostname) The name of the calling workstation
        # @option opt [Boolean] :use_default_target (False) Use the domain supplied by the server in the Type 2 packet
        # @note An empty :domain option authenticates to the local machine.
        # @note The :use_default_target has presidence over the :domain option
        def response(arg, opt = {})
          usr = arg[:user]
          pwd = arg[:password]
          domain = arg[:domain] ? arg[:domain] : ""
          if usr.nil? or pwd.nil?
            raise ArgumentError, "user and password have to be supplied"
          end

          if opt[:workstation]
            ws = opt[:workstation]
          else
            ws = Socket.gethostname
          end

          if opt[:client_challenge]
            cc  = opt[:client_challenge]
          else
            cc = rand(MAX64)
          end
          cc = NTLM::pack_int64le(cc) if cc.is_a?(Integer)
          opt[:client_challenge] = cc

          if has_flag?(:OEM) and opt[:unicode]
            usr = NTLM::EncodeUtil.decode_utf16le(usr)
            pwd = NTLM::EncodeUtil.decode_utf16le(pwd)
            ws  = NTLM::EncodeUtil.decode_utf16le(ws)
            domain = NTLM::EncodeUtil.decode_utf16le(domain)
            opt[:unicode] = false
          end

          if has_flag?(:UNICODE) and !opt[:unicode]
            usr = NTLM::EncodeUtil.encode_utf16le(usr)
            pwd = NTLM::EncodeUtil.encode_utf16le(pwd)
            ws  = NTLM::EncodeUtil.encode_utf16le(ws)
            domain = NTLM::EncodeUtil.encode_utf16le(domain)
            opt[:unicode] = true
          end

          if opt[:use_default_target]
            domain = self.target_name
          end

          ti = self.target_info

          chal = self[:challenge].serialize

          if opt[:ntlmv2]
            ar = {:ntlmv2_hash => NTLM::ntlmv2_hash(usr, pwd, domain, opt), :challenge => chal, :target_info => ti}
            lm_res = NTLM::lmv2_response(ar, opt)
            ntlm_res = NTLM::ntlmv2_response(ar, opt)
          elsif has_flag?(:NTLM2_KEY)
            ar = {:ntlm_hash => NTLM::ntlm_hash(pwd, opt), :challenge => chal}
            lm_res, ntlm_res = NTLM::ntlm2_session(ar, opt)
          else
            lm_res = NTLM::lm_response(pwd, chal)
            ntlm_res = NTLM::ntlm_response(pwd, chal)
          end

          Type3.create({
            :lm_response => lm_res,
            :ntlm_response => ntlm_res,
            :domain => domain,
            :user => usr,
            :workstation => ws,
            :flag => self.flag
          })
        end
      end

      # @private false
      class Type3 < Message

        string          :sign,          {:size => 8, :value => SSP_SIGN}
        int32LE         :type,          {:value => 3}
        security_buffer :lm_response,   {:value => ""}
        security_buffer :ntlm_response, {:value => ""}
        security_buffer :domain,        {:value => ""}
        security_buffer :user,          {:value => ""}
        security_buffer :workstation,   {:value => ""}
        security_buffer :session_key,   {:value => "", :active => false }
        int64LE         :flag,          {:value => 0, :active => false }

        class << Type3
          # Parse a Type 3 packet
          # @param [String] str A string containing Type 3 data
          # @return [Type2]
          def parse(str)
            t = new
            t.parse(str)
            t
          end

          # Builds a Type 3 packet
          # @note All options must be properly encoded with either unicode or oem encoding
          # @return [Type3]
          # @option arg [String] :lm_response The LM hash
          # @option arg [String] :ntlm_response The NTLM hash
          # @option arg [String] :domain The domain to authenticate to
          # @option arg [String] :workstation The name of the calling workstation
          # @option arg [String] :session_key The session key
          # @option arg [Integer] :flag Flags for the packet
          def create(arg, opt ={})
            t = new
            t.lm_response = arg[:lm_response]
            t.ntlm_response = arg[:ntlm_response]
            t.domain = arg[:domain]
            t.user = arg[:user]

            if arg[:workstation]
              t.workstation = arg[:workstation]
            end

            if arg[:session_key]
              t.enable(:session_key)
              t.session_key = arg[session_key]
            end

            if arg[:flag]
              t.enable(:session_key)
              t.enable(:flag)
              t.flag = arg[:flag]
            end
            t
          end
        end
      end
    end
  end
end
