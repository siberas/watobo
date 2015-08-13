# @private 
module Watobo#:nodoc: all

  module Gui

# Watobo::Gui::History
=begin
    Class for managing history entries
    entries are organised as a hash.
    each entry consists of a hash.
    the key of an entry is based on its session filename

    @history_entry[session_file] = {
    :last_used
    :created
    :project_name
    :session_name
    :description
    }
=end
    class SessionHistory

      attr_accessor :max_entries
      def save()
        begin
          File.open(@history_file,"w") { |fh| fh.write YAML.dump(@history_entries) }
        rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        end
      end

      def entries
        @history_entries
      end

      def add_entry(prefs = {})
        t_now = Time.now.to_i
        return false unless prefs.has_key? :session_name or prefs.has_key? :project_name
        puts "#"
        hid = history_id(prefs[:project_name], prefs[:session_name])
        @history_entries[hid] ||= {
          :created => t_now
        }
        @history_entries[hid][:last_used] = t_now

        [ :description, :project_name, :session_name ].each do |k|
          @history_entries[hid][k] = prefs[k] if prefs.has_key? k
        end

        while @history_entries.length > @max_entries do
          oid, ov = @history_entries.min_by{ |id,v| v[:last_used] }
          @history_entries.delete oid
        end

        save()
      end

      def delete_entry(project_name, session_name)
        @history_entries.delete history_id(project_name, session_name)
      end

      def update_usage(prefs)
        t_now = Time.now.to_i
        return false unless prefs.has_key? :session_name or prefs.has_key? :project_name
        hid = history_id(prefs[:project_name], prefs[:session_name])
        return false unless @history_entries.has_key? hid
        @history_entries[hid][:last_used] = t_now
        save()
      end

      def each(&b)
        @history_entries.each_key{ |k|
          yield @history_entries[k] if block_given?
        }
      end

      def load(history_file)
        if File.exist? history_file
        @history_entries = YAML.load_file(history_file)
        end
      end

      def initialize(filename)

        @max_entries = 8
        @history_entries = Hash.new
        @history_file = filename

        if File.exist? @history_file
        load(@history_file)
        else
          begin
            File.open(@history_file,"w") { |fh| fh.write YAML.dump(@history_entries) }
          rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          end
        end

      end

      private

      def history_id(project_name, session_name)
        text = [ project_name, session_name ].join("$")
        return Digest::MD5.hexdigest(text)
      end

    end

  end

end