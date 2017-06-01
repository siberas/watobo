# @private 
module Watobo#:nodoc: all
  module Gui
    class ChecksPolicyFrame < FXVerticalFrame

     # attr :policy_name
      def onPolicyChanged(sender, sel, item)
        @policy_name = @policyCombo.getItemText(@policyCombo.currentItem)
        policy = @policyCombo.getItemData(@policyCombo.currentItem)
        applyPolicy(policy)
      end

      def applyPolicy(policy=nil)
        #return false if policy.nil?
        tree_elements = []
        @checks.each do |check|
          status = true
          begin
          #  status = policy[check.class.to_s]
          status = false
          rescue
          puts "unknown policy or unknown test [#{@policy}] - [#{check.class.to_s}"
          end
          a = {
            :name => "#{check.check_group}|#{check.check_name}",
            :enabled => status,
            :data => check
          }
          tree_elements.push a
        end

        showTree(tree_elements)
      end

      def set_checks(elements, policy={})
        tree_elements = []
        @checks.each do |check|
          a = {
            :name => "#{check.check_group}|#{check.check_name}",
            :enabled => false,
            :data => check
          }
          puts a[:name]
          tree_elements.push a
        end

        showTree(tree_elements)
      end

      def showInfo(check)

      end

      def showTree(elements)
        @tree.elements = elements
      end

      def getSelectedModules()
        sel = @tree.getCheckedData
      
      #sel.map { |i| p i.class }
      end

      def initialize(parent, policy=nil)
        # Invoke base class initialize function first
        super(parent, :opts => LAYOUT_FILL_X| LAYOUT_FILL_Y, :padding => 0)

        self.extend Watobo::Gui::Events

         @checks = Watobo::ActiveModules.to_a
        #@checks = Watobo.active_checks
=begin        
        @policy_list = policy.is_a?(Hash) ? policy : default_policy(checks)         # policy settings

        policy_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        policy_name = @policy_list[:default_policy] if @policy_list.has_key? :default_policy
        @current_policy = @policy_list[policy_name] if @policy_list.has_key? policy_name

        policy_count = ( @policy_list.is_a? Hash ) ? @policy_list.length : 0

        @policyCombo = FXComboBox.new(policy_frame, policy_count, nil, 0,
        COMBOBOX_INSERT_LAST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

        @policyCombo.numVisible = policy_count
       # @policyCombo.connect(SEL_COMMAND, method(:onPolicyChanged))
=end        
         quickSelectFrame = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        @sel_all_btn = FXButton.new(quickSelectFrame, "Select All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @sel_all_btn.connect(SEL_COMMAND){ 
          @tree.checkAll
          @tree.update
        }
        
      #  @sel_all_btn.setFocus()
      #  @sel_all_btn.setDefault()
        
        @desel_all_btn = FXButton.new(quickSelectFrame, "Deselect All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @desel_all_btn.connect(SEL_COMMAND){ 
          @tree.uncheckAll
          @tree.update 
        } 

        tree_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        @tree = CheckBoxTreeList.new(tree_frame)

        @tree.subscribe(:sel_command){
          puts '!! TREE SEL_COMMAND'
          notify(:sel_command)
          false
        }

        #if @policy_list
        #  @policy_list.each do |pname, p|
        #    next if pname.is_a? Symbol
        #    @policyCombo.appendItem(pname, p)
        #  end
        # # select policy
        #  index = @policyCombo.findItem(policy_name)
        #  if index >= 0 then
        #  @policyCombo.setCurrentItem(index)
        #  end
        #applyPolicy(@current_policy)
        #end
        #applyPolicy()
        set_checks @checks
      end

      private

      def default_policy(checks)
        @policy_list = Hash.new
        @policy_list[:default_policy] = 'default'
        dp = @policy_list['default'] = Hash.new
        checks.each do |ac|
          dp[ac.class.to_s] = false
        end
        @current_policy = dp
        @policy_list
      end
    end
  #--
  end
end
