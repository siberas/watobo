# @private 
module Watobo#:nodoc: all
  module Plugin
    module Sslchecker
      class Check < Watobo::ActiveCheck
        attr :cipherlist
        
         @info.update(
          :check_name => 'SSL-Checker',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Test applikation for supportes SSL Ciphers.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'Attacks on weak encryption ciphers which may lead loss of privacy',        # thread of vulnerability, e.g. loss of information
          :class => "SSL Ciphers",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_LOW
          )
          
          
        def initialize(project)
          super(project)

          @result = Hash.new
          @cipherlist = Array.new
          
          
          OpenSSL::SSL::SSLContext::METHODS.each do |method|
            next if method =~ /(client|server)/
            next if method =~ /23/
          #%w( TLSv1_server SSLv2_server SSLv3_server ).each do |method|
            puts ">> #{method}"
            begin
          ctx = OpenSSL::SSL::SSLContext.new(method)
          ctx.ciphers="ALL::COMPLEMENTOFALL::eNull"
          ctx.ciphers.each do |c|
            @cipherlist.push [ method, c[0]]
          end
          #ctx.ciphers="eNULL" # because ALL don't include Null-Ciphers!!!
          #ctx.ciphers.each do |c|
          #  @cipherlist.push [ method, c[0]]
          #end

          
          rescue => bang
            puts bang
          end
          
          end
         # puts @cipherlist.to_yaml
        end

        def reset()
          @result.clear
        end
        
        def check_cipher(request, method, cipher)
          begin
          @lasterror = nil
          response_header = nil
          
          site = request.site
       
          proxy = Watobo::ForwardingProxy.get(site)
          unless proxy.nil?
          puts "* a proxy is configured for site #{site}"
          end

          host = request.host
          port = request.port
          
          # check if hostname is valid and can be resolved
          hostip = IPSocket.getaddress(host)
          
        rescue SocketError
          puts "!!! unknown hostname #{host}"
          puts request.first
          return false, "WATOBO: Could not resolve hostname #{host}", nil
        rescue => bang
          #puts bang
          puts bang.backtrace if $DEBUG
        end
        
        begin
         tcp_socket = nil
         tcp_socket = TCPSocket.new( host, port )
         tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)    
         tcp_socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
         tcp_socket.sync = true
         socket =  tcp_socket
         
         ctx = OpenSSL::SSL::SSLContext.new(method)
         ctx.ciphers = cipher
         socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)
         socket.sync_close = true

         socket.connect
        rescue => bang
          puts bang
          return false
        end
          true
        end
        
        def generateChecks(chat)
          begin
            @cipherlist.each do |method, c|
            checker = proc {

              test_request = nil
              test_response = nil
              # !!! ATTENTION !!!
              # MAKE COPY BEFORE MODIFIYING REQUEST
              request = chat.copyRequest

              
                ctx = OpenSSL::SSL::SSLContext.new(method)
                ctx.ciphers = c
                cypher = ctx.ciphers.first
                bits = cypher[2].to_i
                algo = cypher[0]
                
                result = {
                    :method => method, 
                    :algo => algo, 
                    :bits => bits, 
                    :support => true
                  }
              
                if check_cipher(request, method, c) == true 
              
                  notify( :cipher_checked, result)
                  if bits < 128

                  addFinding(  test_request, test_response,
                  :test_item => "#{algo}#{bits}",
                  #:proof_pattern => "#{match}",
                  :chat => chat,
                  :title => "[#{algo}] - #{bits} Bit"
                  )
                  end
                else
                  result[:support] = false
                notify(:cipher_checked, result)
                #              puts "!!! ERROR: #{c}"
                end
              
              [ test_request, test_response ]

            }
            yield checker
            end
          rescue => bang
          puts "!error in module #{Module.nesting[0].name}"
          puts bang
          end
        end
  


        def generateChecks_UNUSED(chat)
          begin
            @cipherlist.each do |method, c|
            checker = proc {

              test_request = nil
              test_response = nil
              # !!! ATTENTION !!!
              # MAKE COPY BEFORE MODIFIYING REQUEST
              request = chat.copyRequest

              
                ctx = OpenSSL::SSL::SSLContext.new(method)
                ctx.ciphers = c
                cypher = ctx.ciphers.first
                bits = cypher[2].to_i
                algo = cypher[0]
              
                test_request, test_response = doRequest( request, :ssl_cipher => c )
                result = {
                    :method => method, 
                    :algo => algo, 
                    :bits => bits, 
                    :support => true
                  }
              
                unless test_response.status =~ /555/ 
                  
              
                  notify( :cipher_checked, result)
                  if bits < 128

                  addFinding(  test_request, test_response,
                  :test_item => "#{algo}#{bits}",
                  #:proof_pattern => "#{match}",
                  :chat => chat,
                  :title => "[#{algo}] - #{bits} Bit"
                  )
                  end
                else
                  result[:support] = false
                notify(:cipher_checked, result)
                #              puts "!!! ERROR: #{c}"
                end
              
              [ test_request, test_response ]

            }
            yield checker
            end
          rescue => bang
          puts "!error in module #{Module.nesting[0].name}"
          puts bang
          end
        end
      end

      
    end
  end
end


