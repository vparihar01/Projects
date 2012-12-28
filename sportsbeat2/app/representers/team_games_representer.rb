module TeamGamesRepresenter
  include Roar::Representer::JSON::HAL

  property :season_id
  property :team_id

  collection :games,
    :class => Game,
    :extend => GameRepresenter,
    :embedded => true

  collection :teams,
    :class => Team,
    :extend => TeamRepresenter,
    :embedded => true

  collection :schools,
    :class => School,
    :extend => SchoolRepresenter,
    :embedded => true

  link :self do
    self[:url]
  end

  link :games_nearest do
    games_nearest_team_url self[:team]
  end

  link :games_latest_season do
    games_team_url self[:team]
  end

  def team
    self[:team]
  end

  def team_id
    self[:team].id
  end

  def teams
    team_ids = []

    games.each do |g|
      team_ids << g.home_team_id
      team_ids << g.away_team_id
    end

    team_ids.uniq!

    Team.joins(:game_teams).where(:game_teams => {:team_id => team_ids }).group(:team_id)
  end

  def schools
    school_ids = []

    teams.each do |t|
      school_ids << t.school_id
    end

    school_ids.uniq!

    School.where(:id => school_ids)
  end

  def games
    self[:games]
  end

  def season_id
    self[:season_id]
  end
end