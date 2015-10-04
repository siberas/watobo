# @private
module Watobo#:nodoc: all
  module HTTP
    class Xml

      module Mixin
        def xml
            @xml ||= Watobo::HTTP::Xml.new(self)
        end
      end

      def to_s
        s = @root.body.to_s
      end

      def set(parm)
        return false unless parm.location == :xml
       # puts "= set "
       # puts parm.to_yaml
        
        doc = Nokogiri::XML(@root.body.strip)
        namespaces = doc.collect_namespaces
        parent = doc.xpath("//#{parm.parent}", namespaces).first
        if parent.nil?
          puts "* could not find parent node #{parm.parent}"
          return false
        end
        
        parm_name = parm.namespace.nil? ? "" : parm.namespace
        parm_name << parm.name
        # find node
        node = parent.xpath("//#{parm_name}", namespaces).first
        if node.nil?
          puts "* node does not exist #{parm_name}"
        end
        
        child = node.children.first
        if child.nil?
          child = Nokogiri::XML::Text.new(parm.value, node)
          node.add_child child
        else        
          child.content = parm.value
        end
        
        @root.set_body doc.to_s

      end

      def has_parm?(parm_name)
        false
      end

      def parameters(&block)
        params = []

        return params unless @root.is_xml?
        leaf_nodes do |n|
          p = { :name => n.name }
          val = n.children.size == 0 ? "" : n.children.first.to_s

            p[:value] = val
            parent_name = ""
            unless n.parent.namespace.nil?
              parent_name << n.parent.namespace.prefix
              parent_name << ":"  
            end
            parent_name << n.parent.name
            p[:parent] = "#{parent_name}"

            unless n.namespace.nil?
              p[:namespace] = n.namespace.prefix
            end
          param = XmlParameter.new(p)
          yield param if block_given?
          params << param
        end

        return params
      end

      def initialize(root)
        @root = root

      end

      private

      def leaf_nodes(&block)

        nodes = []
        begin
          doc = Nokogiri::XML(@root.body.strip)
          prefix = doc.children.first.namespace.prefix
          # check if doc has a body element
          start = doc
          doc.traverse { |node|
            if node.name =~ /^body$/i
            start = node
            end
          }
          start.traverse { |node|
             if node.children.size == 0 and node.is_a? Nokogiri::XML::Element
               yield node if block_given?
               nodes << node
             end
            if node.children.size == 1
              if node.children.first.is_a? Nokogiri::XML::Text
                yield node if block_given?
                nodes << node
              end
            end
          }
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        nodes
      end

    end
  end
end