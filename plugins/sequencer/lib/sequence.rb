module Watobo
  class Sequence < Array

    def self.create(filename)
      begin
        prefs = {}
        if File.exist?(filename) then
          File.open(filename, "rb") { |f|
            prefs = Marshal::load(f.read) rescue nil
            prefs = JSON.parse(IO.binread(f)) unless prefs
            prefs[:file] = filename
          }
        end
      rescue => bang
        puts bang
        puts bang.backtrace

      end

      seq = Sequence.new prefs
      # Watobo::Sequences.add seq
      seq
    end

    attr :name, :file, :env

    def add(element)
      self << element
    end

    def update_env(env)
      @env = env
    end

    def to_h
      h = {}
      h[:name] = @name
      h[:file] = @file
      h[:elements] = []
      each do |e|
        h[:elements] << e.to_h
      end
      h[:env] = @env || {}
      h
    end

    def initialize(prefs)
      init(prefs)
    end

    private

    def init(prefs)
      prefs.transform_keys!(&:to_sym)
      @name = prefs[:name]
      @file = prefs[:file]
      if prefs.has_key? :elements
        prefs[:elements].each do |element|
          self << Watobo::Plugin::Sequencer::Element.new(self, element)
          # binding.pry
        end
      end

      if prefs.has_key? :env
        #   prefs[:vars].each do |var|

        #end
      end

      @env = prefs[:env]
    end

    def method_missing?(name, *args, &block) end

  end
end