module Watobo #:nodoc: all
  module Plugin
    class Filescanner

      class Check < Watobo::ActiveCheck
        include Watobo::Evasions

        attr :prefs
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

        def append_slash?
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
        #  evasion_extensions: [Array]
        #  force_evasions: [Bool]
        def initialize(project, file_list, prefs = {})
          super(project, prefs)

          @path = nil
          @file_list = file_list
          @prefs = prefs.dup.to_h
          @known_responses = []
          @known_paths = []
          @rating = @prefs.delete(:rating) || VULN_RATING_LOW
        end

        def reset()
          @known_responses = []
          @known_paths = []
          # @catalog_checks.clear
        end

        # create final path list for fileExist checks
        # @return [Array] of modified paths including the query for filter evasion
        # original query will be removed
        def sample_files(&block)
          uris = []
          @file_list.each do |orig|
            next if orig.strip =~ /^#/
            orig.strip!
            # remove leading '.' and '/'
            orig.gsub!(/^[\/\.]+/, '')
            # remove trailing slashes
            orig.gsub!(/\/$/, '')
            next if orig.strip.empty?

            # first we save the original
            uris << orig

            # we keep the orig path also in the extended array
            # for later evasions
            extended = [orig]

            # append extensions
            #
            file_extensions.each do |ext|
              next if ext.nil? or ext.empty?
              fext = ext =~ /^\./ ? ext : ".#{ext}"
              extended << apply_extension(orig, fext)
            end

            extended.each do |mpath|
              evasion_extensions.each do |ext|
                next if ext.nil? or ext.empty?
                uris << apply_extension(mpath, ext)
              end
            end
            # append slash (only to orig)
            uris << "#{orig}/" if append_slash?

          end
          uris.compact!
          uris.uniq
        end

        def apply_extension(orig, ext, &block)
          return nil if orig.nil? || orig.empty?
          return nil if ext.nil? || ext.empty?

          dummy = Watobo::Request.new 'http://my.dummy.url'
          dummy.path = orig

          # file extensions start with '.', e.g. '.tar.gz'
          if ext =~ /^\./
            dummy.set_file_extension ext, :keep_query
            return dummy.path_ext
          end

          # if extension starts with / it means that it's a path modification
          # e.g. '/;' will make orig path '/xxx/y.php' to '/xxx;/y.php'
          if ext =~ /^\//
            file_ext = dummy.file_ext
            dir = dummy.dir
            return "#{dir}#{ext.gsub(/^\//, '')}/#{file_ext}"
          end
          # if extension starts with '?' it is handled as a query extension
          if ext =~ /^\?(.*)/
            dummy.appendQueryParms $1
            return dummy.path_ext
          end

          # seems like a bad extension format
          return nil
        end

        def generateChecks(chat)
          begin
            sample_files.each do |uri|
              request_paths(chat) do |rpath|
                next if @known_paths.include?(rpath)

                test_request = nil
                test_response = nil
                # !!! ATTENTION !!!
                # MAKE COPY BEFORE MODIFIYING REQUEST
                sample = chat.copyRequest
                sample.set_path rpath

                # puts ">> #{new_uri}"
                sample.replaceFileExt(uri)
                file_exist = false

                checker = proc {

                  found = false
                  need_evasion = false

                  # puts sample.url.to_s
                  fexist, test_request, test_response = fileExists?(sample, @prefs)

                  if test_response.respond_to? :status_code
                    status = test_response.status_code
                    need_evasion = ( status =~ /^4\d\d/ && status != '404' )
                  end

                  chat = Chat.new(test_request, test_response, :id => 0, :chat_source => prefs[:chat_source])
                  notify(:new_chat, chat)

                  if fexist == true
                    found = true
                    rhash = Watobo::Utils.responseHash(test_request, test_response)
                    unless @known_responses.include?(rhash)
                      @known_responses << rhash
                      addFinding(test_request, test_response,
                                 :test_item => uri,
                                 # :proof_pattern => "#{Regexp.quote(uri)}",
                                 :check_pattern => "#{Regexp.quote(uri)}",
                                 :chat => chat,
                                 :threat => "depends on the file ;)",
                                 :title => "[#{uri}]",
                                 :rating => @rating.to_i

                      )
                    end

                  end
                  # binding.pry
                  if need_evasion or !!@prefs[:force_evasions]
                    evasion_handlers.each do |handler|
                      # puts test.url if $VERBOSE

                      next if found

                      handler.run(sample) do |test|
                        fexist, test_request, test_response = fileExists?(test, @prefs)

                        chat = Chat.new(test_request, test_response, :id => 0, :chat_source => prefs[:chat_source])
                        notify(:new_chat, chat)

                        if fexist == true
                          found = true
                          rhash = Watobo::Utils.responseHash(test_request, test_response)
                          unless @known_responses.include?(rhash)
                            @known_responses << rhash
                            addFinding(test_request, test_response,
                                       :test_item => uri,
                                       # :proof_pattern => "#{Regexp.quote(uri)}",
                                       :check_pattern => "#{Regexp.quote(uri)}",
                                       :chat => chat,
                                       :threat => "depends on the file ;)",
                                       :title => "[#{uri}]",
                                       :rating => @rating.to_i

                            )
                          end

                        end
                      end
                    end
                  end
                  # we don't need to return request and response, because it's already upwarded via notify(:new_chat)
                  #[test_request, test_response]
                  [ nil, nil]
                }
                yield checker
              end

            end
          rescue => bang
            puts "!error in module #{Module.nesting[0].name}"
            puts bang
          end
        end

        def request_paths(chat, &block)
          # binding.pry
          unless !!@prefs[:test_sub_dirs]
            yield chat.request.path if block_given?
            return chat.request.path
          end
          paths = []
          path = chat.request.path
          while !path.empty? and path != '.'
            # puts path
            yield path if block_given?
            paths << path
            path = File.dirname(path)
          end
          paths
        end
      end
    end
  end
end

