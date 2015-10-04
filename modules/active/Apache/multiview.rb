=begin
http://www.wisec.it/sectou.php?id=4698ebdc59d15

$ curl -i -H "Negotiate: watobo" http://192.168.70.134/index
HTTP/1.1 406 Not Acceptable
Date: Fri, 24 Jan 2014 08:46:35 GMT
Server: Apache/2.2.22 (Debian)
Alternates: {"index.bak" 1 {type application/x-trash} {length 0}}, {"index.html" 1 {type text/html} {length 177}}, {"index.tgz" 1 {type application/x-gzip} {length 0}}
Vary: negotiate,accept,Accept-Encoding
TCN: list
Content-Length: 568
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>406 Not Acceptable</title>
</head><body>
<h1>Not Acceptable</h1>
<p>An appropriate representation of the requested resource /index could not be found on this server.</p>
Available variants:
<ul>
<li><a href="index.bak">index.bak</a> , type application/x-trash</li>
<li><a href="index.html">index.html</a> , type text/html</li>
<li><a href="index.tgz">index.tgz</a> , type application/x-gzip</li>
</ul>
<hr>
<address>Apache/2.2.22 (Debian) Server at 192.168.70.134 Port 80</address>
</body></html>

=end

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Apache
        
        
        class Multiview < Watobo::ActiveCheck
          
          @@tested_paths = []
          
          details =<<EOD           
$ curl -i -H "Negotiate: watobo" http://192.168.70.134/index
HTTP/1.1 406 Not Acceptable
Date: Fri, 24 Jan 2014 08:46:35 GMT
Server: Apache/2.2.22 (Debian)
Alternates: {"index.bak" 1 {type application/x-trash} {length 0}}, {"index.html" 1 {type text/html} {length 177}}, {"index.tgz" 1 {type application/x-gzip} {length 0}}
Vary: negotiate,accept,Accept-Encoding
TCN: list
Content-Length: 568
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>406 Not Acceptable</title>
</head><body>
<h1>Not Acceptable</h1>
<p>An appropriate representation of the requested resource /index could not be found on this server.</p>
Available variants:
<ul>
<li><a href="index.bak">index.bak</a> , type application/x-trash</li>
<li><a href="index.html">index.html</a> , type text/html</li>
<li><a href="index.tgz">index.tgz</a> , type application/x-gzip</li>
</ul>
<hr>
<address>Apache/2.2.22 (Debian) Server at 192.168.70.134 Port 80</address>
</body></html>
EOD
          
           @info.update(
                         :check_name => 'MultiViews',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks if MultiViews option is present in Apache. See http://www.wisec.it/sectou.php?id=4698ebdc59d15",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :check_group => AC_GROUP_APACHE,
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => 'Makes enumeration of backup or renamed files easier. see also http://www.wisec.it/sectou.php?id=4698ebdc59d15',        # thread of vulnerability, e.g. loss of information
            :class => "MultiViews",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :rating => VULN_RATING_INFO,
            :measure => "Disable MultiViews in your Apache configuration.",
            :details => details,
            :type => FINDING_TYPE_VULN         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
          
          def initialize(session_name=nil, prefs={})
          #  @project = project
            super(session_name, prefs)
            
            #  @tested_directories = Hash.new
            @fext = %w( php asp aspx jsp cfm shtm htm html shml )
            
          end
          
          def reset()
            @@tested_paths.clear
          end
          
          
          def generateChecks(chat)
            
            begin
              file = chat.request.file              
              return nil if @@tested_paths.include? file
              @@tested_paths << file
              
              if file != "" and file =~ /\.(#{@fext.join("|")})$/ then
                 checker = proc{
                      test_request = nil
                      test_response = nil
                      new_file = file.gsub(/\.\w{1,4}$/, "")
                      test_request = chat.copyRequest
                      #test_request.addHeader("Vary","negotiate,accept")
                      test_request.set_header("Accept","application/watobo; q=1.0")
                      
                      test_request.replaceFileExt(new_file)
                      result_request, result_response = doRequest(test_request, :default => true)
                      
                      tcn_headers = result_response.headers("^TCN")
                      unless tcn_headers.empty?                     
                        puts "MULTIVIEW - #{self.class}!!!\n"
                        #test_chat = Chat.new(test_request, test_response, chat.id)
                        addFinding( result_request, result_response,
                                   :check_pattern => "#{new_file}",
                                   :test_item => file,
                        :proof_pattern => "#{new_file}",
                        :chat => chat,
                        :title => "#{new_file}"
                        #:debug => true
                        )                        
                      end
                      [ test_request, test_response ] 
                    }
                    yield checker
              end
            rescue => bang
              
              puts "ERROR!! #{Module.nesting[0].name} "
              puts "chatid: #{chat.id}"
              puts bang
              puts 
              
            end
          end
        end
      end
    end
  end
end
