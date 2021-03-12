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

        def evasion_level
          @prefs.has_key?(:evasion_level) ? @prefs[:evasion_level] : 0
        end

        def set_extensions(extensions)
          @extensions = extensions if extensions.is_a? Array
          @extensions << nil
        end

        def append_slash
          !!@prefs[:append_slash] ? @prefs[:append_slash] : false
        end

        def evasion_extensions
          !!@prefs[:evasion_extensions] ? @prefs[:evasion_extensions] : []
        end

        def file_extensions
          !!@prefs[:file_extensions] ? @prefs[:file_extensions] : []
        end

        # @return Object [ActiveCheck]
        # @param file_list [Array]
        # @param prefs [Hash]
        #  containing Scanner preferences
        #  additionally following keys are accepted:
        #  file_extension: [Array],
        #  append_slash: [Boolean]
        #  evasion_level: [Integer]
        #
        def initialize(project, file_list, prefs)
          super(project, prefs)


          @path = nil
          @file_list = file_list
          @prefs = prefs.to_h
        end


        def reset()
          # @catalog_checks.clear
        end

        # create final path list for fileExist checks
        # @return [Array] of modified paths including the query for filter evasion
        # original query will be removed
        def sample_files
          uris = []
          @file_list.each do |orig|
            next if orig.strip =~ /^#/
            orig.strip!
            # remove leading '.' and '/'
            orig.gsub!(/^[\/\.]+/, '')
            # remove trailing slashes
            orig.gsub!(/\/$/, '')
            next if orig.strip.empty?

            uris << orig
            # append extensions
            #
            file_extensions.each do |ext|
              next if ext.nil? or ext.empty?
              uris << "#{orig}.#{ext}"
            end

            evasion_extensions.each do |ext|
              next if ext.nil? or ext.empty?
              uris << "#{orig}#{ext}"
            end
            # append slash (only to orig)
            uris << "#{orig}/" if append_slash

          end
          uris
        end


        def generateChecks(chat)
          begin
            sample_files.each do |uri|

              checker = proc {
                test_request = nil
                test_response = nil
                # !!! ATTENTION !!!
                # MAKE COPY BEFORE MODIFIYING REQUEST
                test = chat.copyRequest

                # puts ">> #{new_uri}"
                test.replaceFileExt(uri)
                #puts test.url if $VERBOSE
                fexist, test_request, test_response = fileExists?(test, @prefs)


                if fexist == true
                  addFinding(test_request, test_response,
                             :test_item => uri,
                             # :proof_pattern => "#{Regexp.quote(uri)}",
                             :check_pattern => "#{Regexp.quote(uri)}",
                             :chat => chat,
                             :threat => "depends on the file ;)",
                             :title => "[#{uri}]"

                  )

                end

                # notify(:db_finished)
                [test_request, test_response]
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

