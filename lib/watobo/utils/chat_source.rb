module Watobo
  module Utils
    module Chat
      include Watobo::Constants
      # @param [Integer] src id
      # @return readable string
      def self.source_str(src)
        str = case src
              when CHAT_SOURCE_UNDEF
                "Undefined"
              when CHAT_SOURCE_INTERCEPT
                "Interceptor"
              when CHAT_SOURCE_PROXY
                "Proxy"
              when CHAT_SOURCE_MANUAL
                "Manual"
              when CHAT_SOURCE_FUZZER
                "Fuzzer"
              when CHAT_SOURCE_MANUAL_SCAN
                "QuickScan"
              when CHAT_SOURCE_AUTO_SCAN
                "AutoScan"
              when CHAT_SOURCE_SEQUENCER
                "Sequencer"
              else
                "WTF!?"
              end
        str
      end
    end
  end
end