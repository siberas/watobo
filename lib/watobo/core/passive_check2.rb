# @private
module Watobo #:nodoc: all

  # PassiveCheck2
  # The new PassiveCheck version to make it multiprocessor ready for Ractor
  class PassiveCheck2
    include Watobo::Constants

    attr :info


    def create_finding(details)
      t = Time.now

      now = t.strftime("%m/%d/%Y@%H:%M:%S")
      #  @@lock.synchronize {

      new_details = Hash.new
      new_details.update(@finding)
      new_details.update(details)

      new_details[:tstamp] = now

      unless new_details.has_key?(:fid)

        id_string = ''

        id_string << new_details[:chat].request.url.to_s if new_details[:chat]
        id_string << new_details[:class] if new_details[:class]
        id_string << new_details[:title] if new_details[:title]
        id_string << new_details[:unique] if new_details[:unique]

        if id_string.empty? then
          id_string = rand(10000)
        end
        #puts "Finding #{id_string}"
        new_details[:fid] = Digest::MD5.hexdigest(id_string)
      end

      new_details[:module] = self.class.to_s

      if details[:debug] == true then
        puts "---"
        puts new_details[:class]
        puts new_details[:title]
        puts "---"
      end
      request = new_details[:chat].request
      response = new_details[:chat].response
      new_details[:chat_id] = new_details[:chat].id

      # shorten pattern here because of crash in FXRex:match with large patterns
      unless new_details[:proof_pattern].nil?
        new_details[:proof_pattern] = new_details[:proof_pattern].length > 128 ? new_details[:proof_pattern][0..127] : new_details[:proof_pattern]
      end
      unless new_details[:check_pattern].nil?
        new_details[:check_pattern] = new_details[:check_pattern].length > 128 ? new_details[:check_pattern][0..127] : new_details[:check_pattern]
      end

      #  new_details.delete(:chat)

        # we don't create a finding object here, because of Ractor limitations
        # new_finding = Watobo::Finding.new(request, response, new_details)
      new_details
    end

    def enabled?
      @enabled
    end

    def enabled=(status)
      @enabled = status
    end

    def enable
      @enabled = true
    end

    def disable
      @enable = false
    end

    def do_test(chat)
      raise "function do_test not defined"
    end

    def initialize(project)
      @project = project
      @enabled = true

#@event_dispatcher_listeners = Hash.new

      @info = {
          :check_name => '', # name of check which briefly describes functionality, will be used for tree and progress views
          :check_group => '', # groupname of check, will be used to group checks, e.g. :Generic, SAP, :Enumeration
          :description => '', # description of checkfunction
          :author => "not modified", # author of check
          :version => "unversioned", # check version
          :target => nil # reserved
      }

      @finding = {
          :title => 'untitled', # [String] title name, used for finding tree
          :check_pattern => nil, # [String] regex of vulnerability check if possible, will be used for highlighting
          :proof_pattern => nil, # [String] regex of finding proof if possible, will be used for highlighting
          :threat => '', # threat of vulnerability, e.g. loss of information
          :measure => '', # measure
          :class => "undefined", # [String] vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :subclass => nil, # reserved
          :type => FINDING_TYPE_UNDEFINED, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :chat => nil, # related chat must be linked
          :rating => VULN_RATING_UNDEFINED, #
          :cvss => "n/a", # CVSS Base Vector
          :icon => nil, # Icon Type
          :timestamp => nil # timestamp
      }

    end
  end
end
