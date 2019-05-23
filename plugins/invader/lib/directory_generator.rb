require_relative './generator'
module Watobo
  module Plugin
    class Invader
      class DirectoryGenerator < Watobo::Plugin::Invader::Generator

        def run(prefs, &block)
          raise ":directory key missing" unless prefs.has_key?(:directory)

          Dir.glob("#{prefs[:directory]}/*").each do |file|
            yield [ File.basename(file), File.read(file).strip ] if block_given?
          end

        end

        def initialize
          super 'Directory Generator'

        end
      end
    end
  end
end
