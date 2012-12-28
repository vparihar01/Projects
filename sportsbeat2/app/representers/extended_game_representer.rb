module ExtendedGameRepresenter
  include Roar::Representer::JSON::HAL
  include GameRepresenter

  property :home_team,
    :class => Team,
    :extend => TeamRepresenter,
    :embedded => true

  property :away_team,
    :class => Team,
    :extend => TeamRepresenter,
    :embedded => true
end