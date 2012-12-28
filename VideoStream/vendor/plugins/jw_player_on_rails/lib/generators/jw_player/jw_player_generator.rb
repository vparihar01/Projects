class JwPlayerGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  class_option :viral, :type => :boolean, :default => false, :desc => 'Include Viral, a video sharing plugin'

  def copy_jw_player
    copy_file "player#{ options[:viral] ? '-viral' : '' }.swf", 'public/jwplayer/player.swf'
    copy_file 'yt.swf', 'public/jwplayer/yt.swf'
    copy_file 'jwplayer.js', 'public/javascripts/jwplayer.js'
  end
end
