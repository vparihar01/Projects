class DashboardController < ApplicationController
  #before_filter :authenticate_user!
  
  def index
    @preloaded_json = {
      game_schedule_url: games_nearest_team_url(current_user.current_teams.first),
      post_to_url: post_to_url(:users, current_user),
      feed_url: feed_url(:users, current_user, :beat)
    }
  end
end