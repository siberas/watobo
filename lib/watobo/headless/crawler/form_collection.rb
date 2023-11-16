module Watobo
  module Headless
    class Spider
      class FormCollection < Collection
        GET_ATTRIBUTES_JS = <<-JS
var items = {}; 
for (index = 0; index < arguments[0].attributes.length; ++index) { 
  items[arguments[0].attributes[index].name] = arguments[0].attributes[index].value 
};
return items;
        JS
        # scripts for collecting buttons
        FORM_BUTTONS_JS = <<-JS
// var buttons = document.querySelectorAll('.button');
var form = arguments[0];
  var buttons = form.querySelectorAll('.button, button, input[type="submit"], input[type="button"]');
  var clickableButtons = [];
  
  for (var i = 0; i < buttons.length; i++) {
    // Here, you can add more conditions to filter the buttons if necessary
    clickableButtons.push(buttons[i]);
  }
  
  return clickableButtons;
        JS

        def css(element)
          tag_name = element.tag_name
          id = element.attribute('id')
          classes = element.attribute('class').split(' ').join('.')

          # Constructing CSS Selector
          css_selector = tag_name
          css_selector += "##{id}" unless id.empty?
          css_selector += ".#{classes}" unless classes.empty?
          css_selector
        end

        def initialize(driver)
          super()

          forms = driver.find_elements(:tag_name, 'form')
          url = driver.current_url

          # check if elements are still valid, they might be no longer present when DOM has changed
          # during loading phase
          active_forms = forms.select { |e| e.attribute('action') rescue false }

          active_forms.each do |form|

            attrs = driver.execute_script(GET_ATTRIBUTES_JS, form);

            # add plain form without any button to collection
            # if possible this form will be submitted with regular from.submit
            self.concat active_forms.map { |e| Spider::Form.new(url, attrs) }
            # get buttons
            buttons = driver.execute_script(FORM_BUTTONS_JS, form);
            puts "Found #{buttons.length} button on form #{css(form)}"
            # buttons.map!{|b| driver.execute_script(FORM_ATTRIBUTES_JS, b)}

            # add form for each button to collection. Thus it's possible to click each button seperately
            buttons.each do |button|
              self.concat active_forms.map { |e| Spider::Form.new(url, attrs, css(button)) }
            end
          end

        end
      end
    end
  end
end
