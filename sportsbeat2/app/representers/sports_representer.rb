module SportsRepresenter
  include Roar::Representer::JSON::HAL

  collection :sports,
    :class => Sport,
    :extend => SportRepresenter,
    :embedded => true

  def sports
    self
  end
end