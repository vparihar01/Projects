module AthleteRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :user_id
  property :school_id
  property :season_ids, :from => :seasons

  link :self do
    athlete_url self
  end

  link :school do
    school_url school
  end

  link :user do
    user_url user
  end
end