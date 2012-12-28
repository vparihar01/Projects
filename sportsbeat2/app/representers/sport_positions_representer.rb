module SportPositionsRepresenter
  include Roar::Representer::JSON::HAL

  collection :positions,
    :class => Position,
    :extend => PositionRepresenter,
    :embedded => true

  link :self do
    positions_sport_url self
  end
end