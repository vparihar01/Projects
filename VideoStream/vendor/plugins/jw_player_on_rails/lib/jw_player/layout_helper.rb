module JwPlayerOnRails
  module LayoutHelper
    def jw_player_headers
      ViewHelper.reset_player_count

      javascript_include_tag 'jwplayer'
    end
  end
end
