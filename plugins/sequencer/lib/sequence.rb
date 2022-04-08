module Watobo
  class Sequence < Array

    def self.create(filename)
      prefs = {}
      if File.exist?(filename) then
        File.open(filename, "rb") { |f|
          prefs = Marshal::load(f.read)
          prefs[:file] = filename
        }
      end


      seq = Sequence.new prefs
      # Watobo::Sequences.add seq
      seq
    end

    attr :name, :file, :vars

    def add(element)
      self << element
    end

    def to_h
      h = {}
          h[:name] = @name
      h[:file] = @file
      h[:elements] = []
      each do |e|
        h[:elements] << e.to_h
      end
      h[:vars] = @vars
      h
    end

    def initialize(prefs)
      init(prefs)
    end

    private

    def init(prefs)
      @name = prefs[:name]
      @file = prefs[:file]
      if prefs.has_key? :elements
        prefs[:elements].each do |element|
          self << Watobo::Plugin::Sequencer::Element.new(self, element)
            #binding.pry
        end
      end

      if prefs.has_key? :vars
        prefs[:vars].each do |var|

        end
      end

      @vars = prefs[:vars]
    end

    def method_missing?(name, *args, &block)

    end

  end
end