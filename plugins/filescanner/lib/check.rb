module Watobo #:nodoc: all
  module Plugin
    class Filescanner

      class Check < Watobo::ActiveCheck
        attr_accessor :db_file
        attr_accessor :path
        attr_accessor :append_slash

        @info.update(
            :check_name => 'File Scanner', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Test list of file names.", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0" # check version
        )

        @finding.update(
            :threat => 'Hidden files may reveal sensitive information or can enhance the attack surface.', # thread of vulnerability, e.g. loss of information
            :class => "Hidden-File", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_LOW
        )

        def add_extension(ext)
          ext.gsub!(/^\.+/, "")
          @extensions << ext
        end

        def set_extensions(extensions)
          @extensions = extensions if extensions.is_a? Array
          @extensions << nil
        end

        def initialize(project, file_list, prefs)
          super(project, prefs)


          @path = nil
          @file_list = file_list
          @prefs = prefs.to_h
          @extensions = [nil]
          @append_slash = false
        end


        def reset()
          # @catalog_checks.clear
        end

        def generateChecks(chat)
          begin
            @file_list.each do |uri|

              #puts "+ #{uri}"
              @extensions.each do |ext|
                # puts "  + #{ext}"
                next if uri.strip =~ /^#/
                # cleanup dir
                uri.strip!
                uri.gsub!(/^[\/\.]+/, '')
                uri.gsub!(/\/$/, '')
                next if uri.strip.empty?

                checker = proc {
                  test_request = nil
                  test_response = nil
                  # !!! ATTENTION !!!
                  # MAKE COPY BEFORE MODIFIYING REQUEST
                  test = chat.copyRequest
                  new_uri = "#{uri}"
                  unless ext.nil? or ext.empty?
                    new_uri << ".#{ext}"
                  end
                  new_uri << "/" if @append_slash == true
                  # puts ">> #{new_uri}"
                  test.replaceFileExt(new_uri)
                  #  puts test.url
                  fexist, test_request, test_response = fileExists?(test, @prefs)


                  if fexist == true

                    #       puts "FileFinder >> #{test.url}"

                    addFinding(test_request, test_response,
                               :test_item => new_uri,
                               # :proof_pattern => "#{Regexp.quote(uri)}",
                               :check_pattern => "#{Regexp.quote(new_uri)}",
                               :chat => chat,
                               :threat => "depends on the file ;)",
                               :title => "[#{new_uri}]"

                    )

                  end

                  # notify(:db_finished)
                  [test_request, test_response]
                }
                print 'G'
                yield checker
              end
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
