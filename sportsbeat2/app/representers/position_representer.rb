module PositionRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :sport_id
  property :name
  property :abbrev
end