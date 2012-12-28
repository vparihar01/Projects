module RosterRepresenter
  include Roar::Representer::JSON::HAL

  property :season
  property :all_seasons

  property :team,
    :class => Team,
    :extend => TeamRepresenter,
    :embedded => true

  collection :users,
    :class => User,
    :extend => UserRepresenter,
    :embedded => true

  link :self do
    roster_team_url team
  end

  link :team do
    team_url team
  end

  def all_seasons
    team.athlete_seasons
  end

  def self.extended base
    super

    base.all_seasons.each do |s|
      link :rel => s do
        roster_team_url base.team, :season_id => s
      end
    end
  end
end