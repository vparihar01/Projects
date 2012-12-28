require "jw_player/view_helper"
require "jw_player/layout_helper"
# includes the view and layout helpers to ActionView::Base
ActionView::Base.send(:include, JwPlayerOnRails::ViewHelper)
ActionView::Base.send(:include, JwPlayerOnRails::LayoutHelper)
