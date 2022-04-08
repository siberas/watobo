module Watobo
  module HTTPData

    class Multipart
      attr :sections


      # Format:
      # Content-Disposition: form-data; name="file"; filename="bugsbunny.jpg"
      # Content-Type: image/jpeg

      # JFIF``C ... data ...
      #
      class MultipartSection
        attr :headers, :index

        class Header
          attr :name, :subs

          # SubParm
          # Sub-Parameter of Header, e,g, filename
          # Content-Disposition: form-data; name="file"; filename="bugsbunny.jpg"
          class SubParm
            attr_accessor :value, :name

            def to_s
              "#{@name}=\"" + %Q(#{@value}) + "\""
            end

            def parameter
              {
                  sub_name: @name,
                  value: @value
              }

            end

            def set(param)
              @value = param.value
            end

            def initialize(key_val)
              @name, value = key_val.split('=')
              @name.strip!
              value.gsub!(/^"/, '')
              value.gsub!(/"$/, '')
              @value = value
            end
          end

          # END OF SUBPARM
          #
          #
          #


          def to_s
            s = []
            s << "#{@name}: #{@value}"
            @subs.each_value do |sub|
              s << sub.to_s
            end
            s.join('; ')
          end

          def parameters
            parms = []
            parms << { name: @name, value: @value }
            @subs.each_value do |sub|
              parms << sub.parameter
            end
            parms
          end

          def set(param)
            if param.sub_name
              return false unless @subs.has_key?(param.sub_name)
              @subs[param.sub_name].set param
            else
              @value = param.value
            end

          end

          def initialize(line)
            match = line.match(/^(.*)(:){1}(.*)/)
            @name = match[1]
            @subs = {}

            if match[3]
              match[3].split(';').each do |sub|
                sub.strip!
                # first entry should have no '=' sign. It's the main value of the header
                unless sub =~ /=/
                  @value = sub
                  next
                end
                o = SubParm.new(sub)
                @subs[o.name] = o

              end
            end

          end
        end

        # END OF HEADER
        #
        #
        #

        def to_s
          hs = []
          @headers.each_value do |h|
            hs << h.to_s
          end
          s = hs.join("\r\n")
          s << "\r\n\r\n"
          s << @data
          s
        end

        def set(param)
          p_name = param.name
          if  p_name =~ /_multipart_body_/i
            @data = param.value
          else
            if headers.has_key?(p_name)
              return headers[p_name].set param
            end
          end
          false
        end

        def parameters
          parms = []
          parms << { name: '_multipart_body_',
                     index: @index,
                     value: @data
          }
          headers.each do |k,v|
            v.parameters.each do |hp|
              p = { name: k, index: @index }
              p.update hp
              parms << p
            end
          end
          parms
        end

        def initialize(index, section)
          @raw = section
          @headers = {}
          @data = ''
          @index = index

          parse_section

        end


        def parse_section
          # find end of headers (eoh)
          # test for \r\n\r\n and \n\n
          # the pattern with the lower index will be taken
          eoh = nil
          nn_index = @raw.index("\n\n")
          rnrn_index = @raw.index("\r\n\r\n")
          if nn_index && rnrn_index
            eoh = nn_index < rnrn_index ? nn_index : rnrn_index
          elsif nn_index
            eoh = nn_index
          elsif rnrn_index
            eoh = rnrn_index
          end

          unless eoh.nil?
            headers = @raw.slice(0, eoh).split("\n").map { |h| "#{h.strip}\r\n" }
            #body = text.slice(eoh + 2, text.length - 1)
            @data = @raw[eoh + 2..-1]
            @data.strip!
          else
            headers = @raw.split(/\n/).map { |h| "#{h.strip}\r\n" }
            @data = nil
          end

          headers.each do |header|
            o = Header.new header
            @headers[o.name] = o
          end


        end

      end

      # END OF MULTIPART SECTION
      #
      #
      #

      def to_s
        s = "--#{@boundary}\r\n"
        sec_strs = []
        @sections.each do |sec|
          sec_strs << sec.to_s
        end
        s << sec_strs.join("\r\n--#{@boundary}\r\n")

        s << "\r\n--#{@boundary}--"
        s
      end


      def clear
        @root.set_body ''
      end

      def set(parm)
        index = parm.index
        if index
          if @sections[index]
            @sections[index].set parm
          end
        end
        @root.set_body self.to_s
      end

      def parameters(*opts, &block)
        params = []
        @sections.each do |s|
          section_parms = s.parameters
          section_parms.each do |p|
            section_values = {index: s.index}
            p.update section_values
            param = MultipartParameter.new(p)
            yield param if block_given?
            params << param
          end
        end
        params
      end


      def initialize(root)
        @root = root
        @sections = []
        @boundary = nil
        raise "Wrong Content-Type. Should be multipart" unless @root.is_multipart?

        parse_sections

      end

      def parse_sections
        return false unless @root.has_body?
        ct = @root.content_type_ex

        if ct =~ /boundary=([\-\w]+)/i
          @boundary = $1.strip
          chunks = @root.body.to_s.split(/--#{@boundary}[\-]{0,2}[\r\n]{0,2}/)

          i = 0
          chunks.each do |c|
            # skip empty chunks. first chunk is empty because of splitting
            next if c.strip.empty?
            @sections << MultipartSection.new(i, c)
            i += 1
          end
        end
      end


    end
  end
end


if $0 == __FILE__
  require 'devenv'
  require 'watobo'
  require 'pry'


  rdata = <<EOF
POST https://some.doma.in:443/c/Bildergalerie.createasset.html HTTP/1.1
Host: some.doma.in
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0
Accept: */*
Accept-Language: en-US,en;q=0.5
CSRF-Token: eyJleHAiOjE2NDkzMjk0MTEsImlhdCI6MTY0OTMyODgxMX0.LuOPTQiNATlxeK3NaSEfZDa3IJixm75X3ZSMNSJrO5A
Content-Type: multipart/form-data; boundary=---------------------------30560368463335767564895144281
Content-Length: 16291
Connection: close

-----------------------------30560368463335767564895144281
Content-Disposition: form-data; name="file"; filename="bugsbunny.jpg"
Content-Type: image/jpeg

JFIF``C

C."
N_K%)XhZdV*wtBT.d#W k+cs?q*G&Zl3cJn<GiO=[yoiJJn&K=KoK W<y;gHNNRa2Py6=8G23q7Ah[CT2j|Jk{z9G:bSVwEAgf<(f)&OUgB=/7Xxv]|7g<*d9xwvNP>?#wvwrg[}^:/%~!8KD"@wo~S{'I b."=1y@v_5^J>9nK|MoW/d{a;j)5V(/]N'h"bgNV][=_<w6&nO3q77~u?6s:e<PL|ijsYkksb\OvWwgvL9b-n.I+>{}|(6E;2'7Oyn=t6#.}3`=3XKy6fh}YyS|g,S0W5_6c?u7Rb<S~0L9x(*G%vefA.so,2C
299jc\n];h6qg,)robp:$3rvl1el25{J~y[r2Gvmrd7x{1w7xMypV>GK9lZ138F!+y^Y6
>9x,];^6@QHZmA / !@1"0A#%2P`1?:W+B4hr=-Ua:YQ&Y{4ud2<x@otG8~:,Xg!e6
l:l6o`![Ck^.edqj;/vX<U6/>5Y5Ex*a22uo/@|C1x[wMujbHOqwn]V!t\b.#u\fwFg<E,D[tf<Sc<f6kuo1u_(m2X3Uk2/&(H#!"W3/77qGQ\lv7tL"Co^/`ZJbT~2E*Tj-=^K)GRv}4;obYQ:oDk~>0}?aO9u`DkYYse=*5X'+ua7cTi,:h+QRW_'HT^YyFUF%;"%ien^[w!0ukz/@k9%csZ%wCM8"XE87+q|uZ\,m$mWp9LE@$P*A+BY+21Y2mBF.}<oK*<[B3l:0ct_wCEeEkCP6Q5jhixL}^D6G-)*Vr5dFltRH;Z Yta67H!pN32"MUsvy)Ub8QOEo%V
WW|qgeM0an+`#_73Dv7U2'Zh|SJN@R5h5-k6RykJ5r$6Q}=CC](dzjhhT|~_rmY"?%m;jd
-Efb-dRl!gDU Qqi?wg $u/
-----------------------------30560368463335767564895144281
Content-Disposition: form-data; name="fileName"

bugsbunny.jpg
-----------------------------30560368463335767564895144281
Content-Disposition: form-data; name="_charset_"

utf-8
-----------------------------30560368463335767564895144281--

EOF

  request = Watobo::Request.new rdata

  p = request.parameters(:multipart).last
  p.value = "qqq"
  request.set p
  binding.pry
end
