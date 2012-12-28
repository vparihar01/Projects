module SportRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :name
  property :gender_code
  
  link :self do
    sport_url self
  end

  link :positions do
    positions_sport_url self
  end
end