# @private 
module Watobo#:nodoc: all
  module Findings
    class << self
      include Watobo::Subscriber
    end

    @findings = {}
    @findings_lock = Mutex.new
    @event_dispatcher_listeners = Hash.new

    def self.length
      @findings.length
    end

    def self.reset
      @findings = {}
      @event_dispatcher_listeners = Hash.new
    end

    def self.exist?(finding)
      @findings.has_key?(finding.details[:fid])
    end

    def self.set(findings)
      @findings.clear
      findings.each do |f|
      @findings[f.id] = f
      end
    end

    def self.set_UNUSED(finding, prefs)
      @findings_lock.synchronize do
        if @findings.has_key? finding.fid
          @findings[finding.fid].details.update prefs
          Watobo::DataStore.update_finding(finding)
        return true
        end
        return false
      end
    end

    def self.unset_false_positive(finding)
      @findings_lock.synchronize do
        if @findings.has_key? finding.fid
          @findings[finding.fid].unset_false_positive
          Watobo::DataStore.update_finding(finding)
        return true
        end
        return false
      end
    end

    def self.set_false_positive(finding)
      @findings_lock.synchronize do
        if @findings.has_key? finding.fid
          @findings[finding.fid].set_false_positive
          Watobo::DataStore.update_finding(finding)
        return true
        end
        return false
      end
    end

    def self.each(&block)
      if block_given?
        @findings_lock.synchronize do
          @findings.map{|f| yield f }
        end
      end
    end

    def self.delete(finding)
      @findings_lock.synchronize do
        Watobo::DataStore.delete_finding(finding)
        @findings.delete finding.fid        
      end
    end

    def self.add(finding, opts={})
      @findings_lock.synchronize do
        options = {
          :notify => true,
          :save_finding => true
        }
        options.update opts
        puts "[Project] add finding #{finding.fid}" if $DEBUG


        # only add finding if it (its fid) doesn't already exist
        unless @findings.has_key?(finding.fid)
          begin
            @findings[finding.fid] = finding
            notify(:new, finding) if options[:notify] == true

            Watobo::DataStore.add_finding(finding) if options[:save_finding] == true
          rescue => bang
            puts "!!!ERROR: #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

    end

    def self.type_str(type)
      s = case type
          when FINDING_TYPE_INFO
            'info'
          when FINDING_TYPE_HINT
            'hint'
          when FINDING_TYPE_VULN
            'vulnerability'
          else
            'n/a'
          end
      s
    end

  end
end