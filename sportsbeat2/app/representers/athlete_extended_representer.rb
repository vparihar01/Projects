module AthleteExtendedRepresenter
  include Roar::Representer::JSON::HAL
  include AthleteRepresenter

  property :user,
    :class => User,
    :extend => UserRepresenter,
    :embedded => true

  property :school,
    :class => School,
    :extend => SchoolRepresenter,
    :embedded => true

end