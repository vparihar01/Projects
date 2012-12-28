# hacks rails to solve #348
# solution was distilled from this thread: https://rails.lighthouseapp.com/projects/8994/tickets/5702-options_for_select-do-not-select-boolean-values-correctly
# if things break, try disabling this hack
# also compare the definition below to your desired [actionpack]/lib/action_view/helpers/form_options_helper.rb (around line 530)
# verified compatibility for actionpack-3.0.1 - 3.0.3
# TODO: revise the above every time you upgrade rails above 3.0.3 and drop the file as neccessary

module ActionView
  module Helpers
    module FormOptionsHelper
      private
        def extract_selected_and_disabled(selected)
          if selected.is_a?(Proc)
            [ selected, nil ]
          else
            selected = Array.wrap(selected)
            options = selected.extract_options!.symbolize_keys
            [ options.has_key?(:selected) ? options[:selected] : selected, options[:disabled] ]  # hacked line
          end
        end
    end
  end
end