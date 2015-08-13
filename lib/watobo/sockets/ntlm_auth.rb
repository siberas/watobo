# @private 
module Watobo#:nodoc: all
  module HTTPSocket
    module NTLMAuth
     
      def do_ntlm_auth()
        response_header = nil

          auth_request = @request.copy

          ntlm_challenge = nil
          t1 = Watobo::NTLM::Message::Type1.new()
          msg = "NTLM " + t1.encode64

          auth_request.removeHeader("Connection")
          auth_request.removeHeader("Authorization")

          auth_request.addHeader("Authorization", msg)
          auth_request.addHeader("Connection", "Keep-Alive")

          if $DEBUG
            puts "============= T1 ======================="
            puts auth_request
          end
          
          data = auth_request.join + "\r\n"
          @connection.send data
          
          puts "-----------------" if $DEBUG
      
          response_header = []
          rcode = nil
          clen = nil
          ntlm_challenge = nil
          response_header = connection.read_header
          response_header.each do |line|
            if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
              rcode = $1.to_i
              rmsg = $2
            end
            if line =~ /^WWW-Authenticate: (NTLM) (.+)\r\n/
              ntlm_challenge = $2
            end
            if line =~ /^Content-Length: (\d{1,})\r\n/
              clen = $1.to_i
            end
            break if line.strip.empty?
          end
          #        puts "==================="

      if $DEBUG
        puts "--- T1 RESPONSE HEADERS ---"
        puts response_header
        puts "---"
      end
      
      if rcode == 401 #Authentication Required
            puts "[NTLM] got ntlm challenge: #{ntlm_challenge}" if $DEBUG
            return socket, response_header if ntlm_challenge.nil?
          elsif rcode == 200 # Ok
            puts "[NTLM] seems request doesn't need authentication" if $DEBUG
            return socket, Watobo::Response.new(response_header)
          else
        if $DEBUG
              puts "[NTLM] ... !#*+.!*peep* ...."
              puts response_header
      end
            return socket, Watobo::Response.new(response_header)
          end

          # reading rest of response
      rest = ''
          Watobo::HTTPSocket.read_body(socket, :max_bytes => clen){ |d| 
         rest += d
      }

      if $DEBUG
      puts "--- T1 RESPONSE BODY ---"
      puts rest
      puts "---"
      end
          t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
          t3 = t2.response({:user => ntlm_credentials[:username],
            :password => ntlm_credentials[:password],
            :domain => ntlm_credentials[:domain]},
          {:workstation => ntlm_credentials[:workstation], :ntlmv2 => true})

          #     puts "* NTLM-Credentials: #{ntlm_credentials[:username]},#{ntlm_credentials[:password]}, #{ntlm_credentials[:domain]}, #{ntlm_credentials[:workstation]}"
          auth_request.removeHeader("Authorization")
          auth_request.removeHeader("Connection")

         # auth_request.addHeader("Connection", "Close")

          msg = "NTLM " + t3.encode64
          auth_request.addHeader("Authorization", msg)
          #      puts "============= T3 ======================="

          data = auth_request.join + "\r\n"

          if $DEBUG
            puts "= NTLM Type 3 ="
            puts data
          end
          @connection.send data

          response_header = []
          response_header = connection.header
          response_header.each do |line|

            if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
              rcode = $1.to_i
              rmsg = $2
            end
            break if line.strip.empty?
          end

          if rcode == 200 # Ok
             puts "[NTLM] Authentication Successfull" if $DEBUG
          elsif rcode == 401 # Authentication Required
             # TODO: authorization didn't work -> do some notification
            # ...
            puts "[NTLM] could not authenticate. Bad credentials?"
            puts ntlm_credentials.to_yaml
          end

          return socket, Watobo::Response.new(response_header)
        
      end
end
  end
end