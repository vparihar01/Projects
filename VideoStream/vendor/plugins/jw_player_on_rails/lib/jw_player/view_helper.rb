module JwPlayerOnRails
  module ViewHelper
   # This counter is used to generated unique IDs
    @@player_count = 0

    # This module contains the view helper <tt>jw_player</tt>
    def jw_player path, options = {}
      increment_player_count

      options.merge!(flashplayer: "/jwplayer/player.swf", file: path)
      %Q[
<div id="jwplayer_#{@@player_count}">Loading the player...</div>
<script type="text/javascript">
  //<![CDATA[
      jwplayer("jwplayer_#{@@player_count}").setup(#{options.to_json});
  //]]>
</script>
      ].html_safe
    end

    def increment_player_count
      @@player_count += 1
    end

    def self.reset_player_count
      @@player_count = 0
    end
  end
end