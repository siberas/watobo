# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      class Detect_infrastructure < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)

          @info.update(
          :check_name => 'Infrastructure Information',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Searching for information in response body which may reveal information about Plattform, CMS-Systems, Application Server, ...",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'Information about the underlying infrastructure may help an attacker to perform specialized attacks.',        # thread of vulnerability, e.g. loss of information
          :class => "Infrastructure",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @pattern_list = []
          @pattern_list << [ 'Server', '<address>([^<]+)</addr' ]
          @pattern_list << [ 'eZPublish CMS', 'title="(eZ Publish)']
          @pattern_list << [ 'Imperia CMS', 'content=[^>]*(IMPERIA [\d\.]*)']
          @pattern_list << [ 'Typo3 CMS', 'content=[^>]*(TYPO3 [\d\.]* CMS)']
          @pattern_list << [ 'Open Text CMS', 'published by[^>]*(Open Text Web Solutions[\-\s\d\.]*)']
          #<meta name="generator" content="Sefrengo / www.sefrengo.org" >
          #<meta name="author" content="CMS Sefrengo">
          @pattern_list << [ 'Sefrengo CMS', 'content=[^>]*(Sefrengo[\s\d\.]*)']
          @pattern_list << [ 'Tomcat', '(Apache Tomcat\/\d{1,4}\.\d{1,4}\.\d{1,4})' ]
          @pattern_list << [ 'Microsoft-IIS', '<img src="welcome.png" alt="(IIS7)"']
#          When it’s a SharePoint 2010 site, you will get the result is like this: MicrosoftSharePointTeamServices: 14.0.0.6106
@pattern_list << [ 'SharePoint 2010', 'MicrosoftSharePointTeamServices.*14.0.0.6106']
# And in SharePoint 2007 site, the result is like this: MicrosoftSharePointTeamServices:12.0.0.4518
@pattern_list << [ 'SharePoint 2007', 'MicrosoftSharePointTeamServices.*12.0.0.4518']
          # "vaadinVersion":"7.0.4"
          @pattern_list << [ 'VAADIN }>', 'vaadinVersion":"(\d+\.\d+\.\d+)']
          @pattern_list << [ 'JBoss'    , 'JBoss Web.(\d+\.\d+\.\d+)']

          #@pattern_list << 'sample code'

        end

        def do_test(chat)
          begin
             # puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/ then
                body = chat.response.body_encoded
                @pattern_list.each do |pat|
                  if body =~ /#{pat[1]}/i then
                    #   puts "!!! MATCH !!!"
                    match = $1
                    addFinding(
                    :proof_pattern => "#{match}",
                    :chat => chat,
                    :title => "[#{match}] - #{match.slice(0..21)}"
                    )
                    break
                  end
              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            if $DEBUG
              puts bang.backtrace 
              puts chat.response.join
            end
          end
        end
      end

    end
  end
end
