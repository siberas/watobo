module Watobo
  class Sequence < Array

    def self.create(filename)
      prefs = File.read filename
      prefs[:file] = filename
      seq = Sequence.new prefs
      Watobo::Sequences.add seq
      seq
    end

    attr :name, :file

    def add(element)
      self << element
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
          self << OpenStruct.new(element)
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