module Watobo
  module Utils
    def self.finding2xml(finding,xml)
      fnode = Nokogiri::XML::Node.new("Finding", xml)

      dnode = Nokogiri::XML::Node.new("Request", xml)
      dnode.content = Base64.strict_encode64( finding.request.join )
      fnode << dnode

      dnode = Nokogiri::XML::Node.new("Response", xml)
      dnode.content = Base64.strict_encode64 finding.response.join
      fnode << dnode

      dnode = Nokogiri::XML::Node.new("Details", xml)
      finding.details.each do |k,v|
        d = Nokogiri::XML::Node.new(k.to_s, xml)
        d.content = v
        dnode << d
      end
      fnode << dnode

      fnode
    end
    
    def self.chat2xml(chat,xml)
      fnode = Nokogiri::XML::Node.new("Chat", xml)

      dnode = Nokogiri::XML::Node.new("Request", xml)
      dnode.content = Base64.strict_encode64( chat.request.join )
      fnode << dnode

      dnode = Nokogiri::XML::Node.new("Response", xml)
      dnode.content = Base64.strict_encode64 chat.response.join
      fnode << dnode

      dnode = Nokogiri::XML::Node.new("Details", xml)
      chat.settings.each do |k,v|
        d = Nokogiri::XML::Node.new(k.to_s, xml)
        d.content = v
        dnode << d
      end
      fnode << dnode

      fnode
    end

    def self.exportXML(*prefs)
      # prefs ||= []
      xml = Nokogiri::XML("")
      env = Nokogiri::XML::Node.new("WatoboExportv1", xml)
      xml << env

      if prefs.include? :export_findings

        findings = Nokogiri::XML::Node.new("Findings", xml)
        env << findings

        Watobo::Findings.each do |fid, finding|
          if prefs.include? :scope_only
            if Watobo::Scope.match_site?(finding.request.site)
              if prefs.include? :ignore_fps
                unless finding.false_positive?
                  findings << finding2xml(finding, xml)
                end
              else
                findings << finding2xml(finding, xml)
              end
            end
          else
            if prefs.include? :ignore_fps
              unless finding.false_positive?
                findings << finding2xml(finding, xml)
              end
            else
              findings << finding2xml(finding, xml)
            end
          end
        end
      end

      chats = Nokogiri::XML::Node.new("Chats", xml)
      env << chats

      if prefs.include? :export_chats
        Watobo::Chats.each do |chat|
          if prefs.include? :scope_only
            if Watobo::Scope.match_site?(chat.request.site)
              chats << chat2xml(chat, xml)
            end
          else
              chats << chat2xml(chat, xml)
          end
        end
      end

      xml
    end
  end
end