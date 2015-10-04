# @private 
module Watobo#:nodoc: all
  module Gui
    module MasterPW
      @master_password = ''
      @save_without_master = false
      @save_passwords = false
      # set the master password
      def self.set=(pw)
        @master_password = ''
        return false unless pw.is_a? String
        @master_password = pw
        true
      end

      def self.set?
        return false unless @master_password.is_a? String
        @master_password.empty?
      end

      def self.disable
        @save_without_master = false
        @master_password = ''
      end

      def self.enable
        @save_without_master = true
      end

      def self.save_passwords?
        @save_passwords
      end

      def self.save_passwords=(state)
        @save_passwords = state
      end

      def self.save_without_master=(state)
        @save_without_master = state
      end

      def self.save_without_master?
        @save_without_master
      end

      # retrieve the master password
      def self.get
        @master_password
      end

      # check if master password is set
      def self.enabled?
        return @master_password.empty?
      end

      def self.settings
        s = { :save_passwords => @save_passwords, :save_without_master => @save_without_master }
      end

      def self.settings=(s)
        return false unless s.is_a? Hash
        @save_passwords = s[:save_passwords] if s.has_key? :save_passwords
        @save_without_master = s[:save_without_master] if s.has_key? :save_without_master
        true
      end

    end

  end
end