module GameRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :season_id
  property :datetime
  property :date
  property :time
  property :display_name_for_home_team
  property :display_name_for_away_team
  property :home_team_id
  property :home_team_score
  property :away_team_id
  property :away_team_score
  property :winner_id
  property :winner_score
  property :loser_id
  property :loser_score

  link :self do
    game_url self
  end

  link :home_team do
    team_url home_team
  end

  link :away_team do
    team_url away_team
  end

  def date
    self.datetime.strftime("%m/%d/%Y")
  end

  def time
    self.datetime.strftime("%I:%M%p")
  end

  def display_name_for_home_team
    display_name_for_team home_team
  end

  def display_name_for_away_team
    display_name_for_team away_team
  end
end