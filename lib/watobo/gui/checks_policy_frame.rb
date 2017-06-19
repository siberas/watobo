# @private 
module Watobo #:nodoc: all
  module Gui
    class ChecksPolicyFrame < FXVerticalFrame


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

          tree_elements.push a
        end

        showTree(tree_elements)
      end

      def showInfo(check)
# TODO: Show check details, e.g. with a PopUp
      end

      def showTree(elements)
        @tree.elements = elements
      end

      def getSelectedModules()
        @tree.getCheckedData
      end

      def initialize(parent, policy=nil)
        # Invoke base class initialize function first
        super(parent, :opts => LAYOUT_FILL_X| LAYOUT_FILL_Y, :padding => 0)

        self.extend Watobo::Gui::Events

        @checks = Watobo::ActiveModules.to_a

        quickSelectFrame = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        @sel_all_btn = FXButton.new(quickSelectFrame, "Select All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @sel_all_btn.connect(SEL_COMMAND) {
          @tree.checkAll
          @tree.update
        }

        #  @sel_all_btn.setFocus()
        #  @sel_all_btn.setDefault()

        @desel_all_btn = FXButton.new(quickSelectFrame, "Deselect All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @desel_all_btn.connect(SEL_COMMAND) {
          @tree.uncheckAll
          @tree.update
        }

        tree_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        @tree = CheckBoxTreeList.new(tree_frame)

        # create a notification chain for SEL_COMMAND
        # we can't register the regular way here, because it's already used by the CheckboxTreeList
        @tree.subscribe(:sel_command) {
          notify(:sel_command)
        }

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
