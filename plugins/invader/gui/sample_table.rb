# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class SampleTable < FXTable
          include Watobo::Subscriber

          def sample_set=(sample_set)

            @samples = sample_set
          end

          def updateTable()
            begin

              initTable
              #   puts "[#{self.class.to_s}].refresh - no samples available" if @samples.empty?

              if @samples.empty?
                appendRows(1)
                return
              end

              appendRows(@samples.length)

              puts "[#{self.class.to_s}].refresh - #{@samples.name} (#{@samples.length})"


              @samples.each_with_index do |sample, index|
                chat = sample.chat
                setItemText(index, 0, sample.source)
                setItemText(index, 1, chat.response.status)

                setItemText(index, 2, chat.duration.to_s)

                setItemText(index, 3, chat.checksum)

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

          alias :refreshTable :updateTable

          def initialize(owner, prefs)
            super(owner, prefs)

            @samples = []

            rowHeaderWidth = 0
            rowHeaderMode = LAYOUT_FIX_WIDTH

            connect(SEL_COMMAND, method(:onTableClick))

            connect(SEL_CHANGED) {|sender, sel, item|
              # puts "SEL_CHANGED #{item.row}"
              selectRow(item.row, true)
              #onTableClick(sender, sel, item)
            }

            connect(SEL_SELECTED, method(:onTableClick))

            cornerButton.connect(SEL_COMMAND) do |sender, sel, index|
              #  just a dummy function for disabling default functionality which lets hang watobo
            end


            connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
              unless event.moved?
                #   row = sender.getCurrentRow
                ypos = event.click_y
                row = rowAtY(ypos)
                #  puts "right click on row #{row} of #{@chatTable.numRows}"
                if row >= 0 and row < numRows
                  sample = @samples[row]
                  chat = sample.chat

                  selectRow(row, false)
                  FXMenuPane.new(self) do |menu_pane|
                    submenu = FXMenuPane.new(self) do |sendto_menu|

                      target = FXMenuCommand.new(sendto_menu, "Manual Request")
                      target.connect(SEL_COMMAND) {
                        open_manual_request_editor(chat)
                      }

                    end
                    FXMenuCascade.new(menu_pane, "Send to", nil, submenu)

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

          def open_manual_request_editor(chat)
            begin
              mrtk = ManualRequestEditor.new(FXApp.instance, Watobo.project, chat)

              mrtk.create

              mrtk.subscribe(:show_browser_preview) {|request, response|
                openBrowser(request, response)
              }

              mrtk.subscribe(:new_chat) {|c|
                Watobo::Chats.add c
              }
              mrtk.show(Fox::PLACEMENT_SCREEN)
            rescue => bang
              puts "!!! could not open manual request"
              puts bang
            end
          end

          def initTable()
            clearItems(false)
            setTableSize(0, 4)

            setColumnText(0, "Sample")
            setColumnText(1, "Code")
            setColumnText(2, "Duration")
            setColumnText(3, "Checksum")

            rowHeader.width = 0
            setColumnWidth(0, 100)

            setColumnWidth(1, 200)
            setColumnWidth(2, 80)
            setColumnWidth(3, 300)

          end

          def onTableClick(sender, sel, item)
            begin

              row = item.row
              selectRow(row, false)
              getRowText(row).to_i - 1

              unless @samples[row].nil?
                chat = @samples[row].chat
                notify(:chat_selected, chat) unless chat.nil?
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
