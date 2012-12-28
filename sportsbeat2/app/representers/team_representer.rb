module TeamRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :school_id
  property :sport_id
  property :level
  property :gender
  property :display_name_with_sport_and_gender, :from => :display_name
  collection :seasons

  link :self do
    team_url self
  end

  link :games_nearest do
    games_nearest_team_url(self)
  end

  link :games_latest_season do
    games_team_url self
  end

  link :seasons do
    season_links = []

    self.seasons.each do |s|
      season_links << games_team_url(self, :season_id => s)
    end

    season_links
  end
end