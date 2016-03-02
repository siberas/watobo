# @private
module Watobo #:nodoc: all
  module Plugin
    module Crawler
      def self.start_url
        @start_url ||= nil
      end

      def self.start_url=(url)
        # puts "Set Start-URL to #{url}"
        # puts url.class
        begin
          @start_url ||= nil
          @start_url = url

          @start_url = URI.parse(url) unless url.respond_to? :host

        rescue => bang
          puts bang
          @start_url = nil
        end

        @start_url
      end

      class Gui < Watobo::Plugin2
        class PasswordMatchError < StandardError;
        end

        class UsernameError < StandardError;
        end

        icon_file "crawler.ico"

        include Watobo::Constants
        include Watobo::Plugin::Crawler::Constants

        def updateView

        end

        def start_url
          url = url_valid? ? URI.parse(@url_txt.text) : nil
          return url
        end

        def settings
          @settings_tabbook
        end

        def set_tab_index(index)
          @settings_tabbook.setCurrent index
        end

        def initialize(owner, project=nil, chat=nil)
          super(owner, "Crawler", project, :opts => DECOR_ALL, :width => 800, :height => 600)
          @plugin_name = "Crawler"
          @project = project
          @status_lock = Mutex.new
          @crawl_status = {
              :engine_status => CRAWL_NONE,
              :page_size => 0,
              :link_size => 0,
              :skipped_domains => 0
          }
          @cookie_jar = nil

          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          FXLabel.new(main, "Start URL, e.g. http://my.target.to/scan/:")
          frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          #  FXLabel.new(frame, "http://")
          @url_txt = FXTextField.new(frame, 60, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)

          @start_button = FXButton.new(frame, "start", :opts => BUTTON_DEFAULT|BUTTON_NORMAL)
          @start_button.disable

          @url_txt.connect(SEL_COMMAND) { |sender, sel, item|
            if url_valid?
              # @start_button.setFocus()
              Watobo::Plugin::Crawler.start_url = start_url
            end
          }

          @url_txt.connect(SEL_CHANGED) {
            update_url_state
          }

          @start_button.connect(SEL_COMMAND) { |sender, sel, item|
            case sender.text
              when /start/i
                start
              when /cancel/i
                cancel
            end
          }

          @crawler = Watobo::Crawler::Engine.new

          @settings_tabbook = SettingsTabBook.new(main)
          @settings_tabbook.general.set @crawler.settings
          @settings_tabbook.auth.crawler = @crawler
          @settings_tabbook.scope.set @crawler.settings

          unless chat.nil?
            begin
              url = chat.request.url
              @url_txt.text = "#{url}"
              chat.request.headers("Authorization") { |h|
                if h =~ /Basic (.*)/i
                  user, pw = Base64.decode64($1).strip.split(":")
                  auth = {:username => user,
                          :password => pw,
                          :auth_type => :basic
                  }
                  @settings_tabbook.auth.set(auth)
                end
              }
              unless chat.request.cookies.empty?
                @cookie_jar = Mechanize::CookieJar.new
                domain = chat.request.host

                chat.request.cookies.each do |c|
                  name, value = c.split("=")
                  cprefs = {:domain => domain,
                            :name => name,
                            :value => value,
                            :path => '/',
                            :expires => (Date.today+1).to_s
                  }
                  cookie = Mechanize::Cookie.new cprefs
                  @cookie_jar << cookie
                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end

          @log_viewer = @settings_tabbook.log_viewer

          @status_frame = StatusFrame.new(main)

          #@crawler.subscribe( :update_status ){ |status|
          #  @status_lock.synchronize do
          #    @crawl_status.update status
          #  end
          #}

          stbk = @settings_tabbook
          [@crawler, stbk.auth].each do |i|
            i.subscribe(:log) { |msg|
              @log_viewer.log(LOG_INFO, msg)
            }
          end

          update_url_state

        end

        private

        def update_url_state
          if url_valid?

            @start_button.enable
          else
            @start_button.disable
            # Watobo::Plugin::Crawler.start_url = nil
          end
        end

        def remove_update_timer
          app = FXApp.instance
          if app.hasTimeout? @update_timer
            app.removeTimeout @update_timer
          end
        end

        #   def add_update_timer(ms=50)
        #     @update_timer = FXApp.instance.addTimeout( ms, :repeat => true) {
        #      update_status
        #     }
        # end
        def on_update_timer
          update_status
        end

        def update_status
          @status_frame.update_status Watobo::Crawler::Status.get
          es = Watobo::Crawler::Status.engine
          unless es.nil?
           # Watobo::Gui.application.runOnUiThread do
              case es
                when CRAWL_NONE
                  @start_button.text = "start"
                when CRAWL_RUNNING
                  @start_button.text = "cancel"

                when CRAWL_PAUSED
                  @start_button.text = "start"
              end
            #end
          end
        end

        def cancel
          remove_update_timer()
          @crawler.cancel
          @start_button.text = "start"
          update_status
        end

        def auth_settings()
          puts "= Authentication Settings ="
          auth = @settings_tabbook.auth.to_h
          # puts auth.to_yaml
          case auth[:auth_type]
            when :basic
              auth[:auth_uri] = start_url
              unless auth[:password] == auth[:retype]
                raise PasswordMatchError, "Passwords Don't Match!"
              end
              if auth[:username].empty?
                raise UsernameError, "Username is empty!"
              end
            when :form
              if auth.has_key? :form
                begin
                  if auth[:form].buttons.length > 0
                    auth[:form].click_button
                    #@crawler.send_form(form).
                  elsif auth[:form].respond_to? :submit
                    puts "Submitting Form"
                    p = auth[:form].submit()
                    #puts p.class
                  end
                rescue => bang
                  puts bang
                end
              end
          end
          puts "---"
          auth
        end

        def scope_settings()
          # puts "= Scope Settings ="
          scope = @settings_tabbook.scope
          ss = scope.to_h
          ss[:root_path] = start_url.path_mp if scope.path_restricted?
          ss
        end

        def general_settings()
          #  puts "= General Settings ="

          gs = @settings_tabbook.general.to_h

        end

        def hook_settings
          hs = @settings_tabbook.hooks.to_h
        end

        def url_valid?
          begin
            return false unless @url_txt.text.strip =~ /^https?:\/\//
            url = URI.parse(@url_txt.text.strip)
            # puts url.host.class
            return true unless url.host.nil?
            return false
          rescue => bang
            puts bang if $DEBUG
            return false
          end
        end

        def start
          return false unless url_valid?

          begin

            prefs ={}
            prefs.update auth_settings
            prefs.update scope_settings
            prefs.update general_settings
            prefs.update hook_settings

            unless @cookie_jar.nil?
              prefs[:cookie_jar] = @cookie_jar
            end

            add_update_timer(1000)

            Thread.new(@url_txt.text, prefs) { |turl, tprefs|
              @crawler.run(turl, tprefs)
            }

            @start_button.text = 'Cancel'

          rescue PasswordMatchError
            #puts "Passwords Don't Match!"
            FXMessageBox.information(self, MBOX_OK, "Password Error", "The provided passwords don't match!")
          rescue UsernameError
            #puts "Passwords Don't Match!"
            FXMessageBox.information(self, MBOX_OK, "Username Error", "Need a valid username.")
          rescue => bang
            puts bang
          end
        end

      end

    end
  end
end
