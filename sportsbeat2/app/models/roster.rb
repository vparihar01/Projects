class Roster
  attr_reader :team, :season

  def initialize team, season = Season.current
    @team = team
    @season = season
  end

  def users
    User.joins(:athletes).joins(:athlete_teams).where(:athlete_teams => {:team_id => @team.id, :season_id => @season.id})
  end
end