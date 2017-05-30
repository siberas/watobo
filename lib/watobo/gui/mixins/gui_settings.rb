# @private 
module Watobo#:nodoc: all

    module Settings

      module Saver

        def inner_filename=(fname)
          @@inner_filename=fname
        end

        def save(&block)
          s = self.to_h
          s = yield(s) if block_given?
          Watobo::Utils.save_settings(@@inner_filename, s)
        end

        def load()
          return false unless File.exist?(@@inner_filename)

          config = Watobo::Utils.load_settings(@@inner_filename)
          self.marshal_load config
          true
        end
      end

      def self.included(base)
        const_set('Settings', OpenStruct.new )
        s = const_get('Settings')
        s.extend Saver

        stack = base.to_s.split('::')

        clazz_name = stack.pop
        grp_name = stack.pop

        subdir = grp_name.nil? ? '' : Watobo::Utils.snakecase(grp_name)
        cname = Watobo::Utils.snakecase(clazz_name)

        wd = Watobo.working_directory

        conf_dir = File.join(wd, 'conf')
        Dir.mkdir conf_dir unless File.exist? conf_dir

        grp_dir = File.join(conf_dir, subdir)
        Dir.mkdir grp_dir unless File.exist? grp_dir

        s.inner_filename = File.join(grp_dir, cname + '_settings.yml')
        s.load


      end
end
end