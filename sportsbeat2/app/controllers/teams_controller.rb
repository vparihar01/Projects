class TeamsController < ApplicationController
  include Roar::Rails::ControllerAdditions
  before_filter :authenticate_user!
  respond_to :json

  def show
    team = Team.find params[:id]
    respond_with team
  end

  def games
    season_id = (params[:season_id] || Season.current).to_i
    team = Team.find params[:id]


    if params[:previous].blank? && params[:upcoming].blank?
      games = team.games.where(:season_id => season_id).order('datetime ASC')
    else
      previous_n = params[:previous].to_i
      upcoming_n = params[:upcoming].to_i
      total = previous_n + upcoming_n

      if previous_n > 0
        previous_games = team.games.previous.where(:season_id => season_id).limit(total).order('datetime DESC').reverse
      else
        previous_games = []
      end

      if upcoming_n > 0
        upcoming_games = team.games.upcoming.where(:season_id => season_id).limit(total).order('datetime ASC').all
      else
        upcoming_games = []
      end

      previous_missing = [previous_n - previous_games.length, 0].max
      upcoming_missing = [upcoming_n - upcoming_games.length, 0].max

      previous_games = previous_games[(total-previous_n-upcoming_missing)..-1] || []
      upcoming_games = upcoming_games[0..(upcoming_n+previous_missing)] || []

      games = previous_games + upcoming_games
    end


    url = games_team_url(team, :season_id => season_id, :previous => params[:previous], :upcoming => params[:upcoming])

    o = {
      :team => team,
      :games => games,
      :season_id => season_id,
      :url => url
    }
    
    respond_with o, :represent_with => TeamGamesRepresenter
  end

  def games_nearest
    params[:previous] ||= 2
    params[:upcoming] ||= 3
    games
  end

  def roster
    season = Season.new params[:season_id]
    t = Team.find params[:id]
    r = Roster.new(t, season)
    respond_with r
  end
end