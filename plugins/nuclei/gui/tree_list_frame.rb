# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Nuclei
      class Gui

        # @subscriptions
        # - sel_command > informs that change of tree selection occured
        # - sel_template_directory >
        class TreeListFrame < FXVerticalFrame

          extend Forwardable

          include Watobo::Subscriber

          def_delegators :@tree, :elements=, :getCheckedData

          def initialize(owner, opts)
            super(owner, opts)
            @config = Watobo::Plugin::Nuclei.config

            @template_dir_dt = FXDataTarget.new(@config.template_dir)
            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP)
            @template_dir_label = FXLabel.new(frame, "Template Directory:")

            @template_dir_text = FXTextField.new(frame, 20,
                                                 :target => @template_dir_dt, :selector => FXDataTarget::ID_VALUE,
                                                 :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X)

            @template_dir_btn = FXButton.new(frame, "Select")
            @template_dir_btn.connect(SEL_COMMAND, method(:selectTemplateDirectory))


            tree_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_THICK | FRAME_SUNKEN, padding: 0)
            @tree = Watobo::Gui::CheckBoxTreeList.new(tree_frame)

            # define notification proxies
            @tree.subscribe(:sel_changed) do
              notify(:sel_changed)
            end

            @tree.subscribe(:item_selected) do |item|
              notify(:item_selected, item)
            end
          end

          private

          def selectTemplateDirectory(sender, sel, item)
            template_dir = FXFileDialog.getOpenDirectory(self, "Select Template Directory", @template_dir_dt.value)
            if template_dir != "" then

              if File.exist?(template_dir) then
                @template_dir_dt.value = template_dir
                @template_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)

                @config.template_dir = template_dir
                @config.save
                notify(:new_template_dir, @template_dir_dt.value)


              end
            end
          end

        end
      end
    end
  end
end
