# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class PayloadFrame < FXVerticalFrame
          include Watobo::Gui
          include Watobo::Gui::Icons

          extend Watobo::Subscriber

          def preferences
            index = @options_switcher.current
            @options_switcher.childAtIndex(index).preferences
          end

          def tweaks
            puts "TWEAKS: #{@tweak_frame.tweaks}"
            @tweak_frame.tweaks
          end

          def initialize(owner, opts)

            super(owner, opts)

            @site_dt = FXDataTarget.new('')

            scroller = FXScrollWindow.new(self, :opts => SCROLLERS_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @scroll_area = FXVerticalFrame.new(scroller, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            gbox = FXGroupBox.new(@scroll_area, "Payload", LAYOUT_SIDE_RIGHT | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)

            frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
            @payload_combo = FXComboBox.new(frame, 5, @site_dt, FXDataTarget::ID_VALUE,
                                            COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)

            @payload_combo.connect(SEL_COMMAND) {set_generator}


            gbox = FXGroupBox.new(@scroll_area, "Options", LAYOUT_SIDE_RIGHT | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            @options_switcher = FXSwitcher.new(gbox, SWITCHER_VCOLLAPSE | LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)


            init_payloads
            #@payload_combo.numColumns = 25
            @payload_combo.editable = false



            #frame = FXVerticalFrame.new(@scroll_area, :opts => LAYOUT_SIDE_TOP | LAYOUT_FILL_X | LAYOUT_FIX_HEIGHT, :height => 200)
            gbox = FXGroupBox.new(@scroll_area, "Tweaks", :opts => LAYOUT_FIX_HEIGHT | LAYOUT_SIDE_RIGHT | FRAME_GROOVE | LAYOUT_FILL_X , :height => 200)
            @tweak_frame = TweakFrame.new(gbox, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_TOP)


          end

          private

          def set_generator

            index = @payload_combo.getCurrentItem
            generator = @payload_combo.getItemData(index)
            Invader::Generator.set generator

            #@options_switcher.current = index
            @options_switcher.setCurrent(index, true)

          end

          def init_payloads
            Invader::GeneratorFactory.each do |generator|
              puts "* create FXFrame for #{generator.class.to_s}"
              # create class name for generator options frame,
              # e.g. Watobo::Plugin::Invader::Gui::<Generator>Options
              base = generator.class.to_s.gsub(/.*::/, '')
              dummy = self.class.to_s.split('::')
              dummy.pop
              dummy << "#{base}Options"

              frame_clazz = Kernel.const_get(dummy.join('::'))

              @payload_combo.appendItem(generator.name, generator)
              frame_clazz.new(@options_switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            end
            @payload_combo.setCurrentItem(0) if @payload_combo.numItems > 0

            set_generator
          end


        end
      end
    end
  end
end
