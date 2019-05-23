# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class TweakTable < FXTable
          include Watobo::Subscriber


          def add_tweak(tweak, update=true)
            @tweaks << tweak
            updateTable if update
            selectRow(@tweaks.length - 1, true)
          end

          def delete_selected
            @tweaks.delete_at currentRow
            updateTable
            selectRow(@tweaks.length - 1, true) unless @tweaks.empty?
          end

          def up_selected
            # TODO: up_selected

          end

          def down_selected
            # TODO: down_selected

          end

          def tweaks
            @tweaks
          end

          def clear
            @tweaks.clear
            updateTable
          end

          def updateTable()
            begin

              initTable

              if @tweaks.empty?
                appendRows(1)
                return
              end

              appendRows(@tweaks.length)

              @tweaks.each_with_index do |tweak, index|

                setItemText(index, 0, tweak.enabled?.to_s)
                setItemText(index, 1, tweak.type)
                setItemText(index, 2, tweak.func.to_s)
                setItemText(index, 3, tweak.info)

                4.times do |i|
                  item = getItem(index, i)
                  item.justify = FXTableItem::LEFT unless item.nil?
                end

              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end

          end

          alias :refresh :updateTable

          def initialize(owner, prefs)
            super(owner, prefs)

            @tweaks = []

            rowHeaderWidth = 0
            rowHeaderMode = LAYOUT_FIX_WIDTH

            connect(SEL_COMMAND, method(:onTableClick))

            connect(SEL_CHANGED) {|sender, sel, item|
              # puts "SEL_CHANGED #{item.row}"
              selectRow(item.row, true)

              #onTableClick(sender, sel, item)
            }

            connect(SEL_SELECTED, method(:onTableClick))


            connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
              unless event.moved?
                #   row = sender.getCurrentRow
                ypos = event.click_y
                row = rowAtY(ypos)
                #  puts "right click on row #{row} of #{@chatTable.numRows}"
                if row >= 0 and row < numRows then
                  proxy = @tweaks[row]

                  selectRow(row, false)

                  FXMenuPane.new(self) do |menu_pane|
                    target = FXMenuCheck.new(menu_pane, "Enabled")
                    target.check = proxy.enabled? ? true : false
                    target.connect(SEL_COMMAND) {
                      proxy.enabled = target.checked?()

                    }

                    menu_pane.create
                    menu_pane.popup(nil, event.root_x, event.root_y)
                    app.runModalWhileShown(menu_pane)
                  end
                  updateTable
                end
              end
            end


            updateTable
          end


          private

          def initTable()
            clearItems(false)
            setTableSize(0, 4)

            setColumnText(0, "Enable")
            setColumnText(1, "Type")
            setColumnText(2, "Action")
            setColumnText(3, "Info")

            rowHeader.width = 0
            setColumnWidth(0, 100)

            setColumnWidth(1, 100)
            setColumnWidth(2, 200)
            setColumnWidth(3, 300)

          end

          def onTableClick(sender, sel, item)
            begin

              row = item.row
              selectRow(row, false)
              getRowText(row).to_i - 1

              unless @tweaks[row].nil?
                tweak = @tweaks[row]
                notify(:tweak_selected, tweak)
              end

            rescue => bang
              puts "[#{self}] ERROR: onTableClick"
              puts bang
              puts bang.backtrace if $DEBUG
            end
          end

        end
      end
    end
  end
end
