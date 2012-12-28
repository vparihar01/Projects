module SchoolRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :name
  property :short_name
  property :address
  property :city
  property :state
  property :zip
  property :latitude
  property :longitude
  property :mascot

  collection :teams,
    :class => Team,
    :extend => TeamRepresenter,
    :embedded => true

  link :self do
    school_url(self)
  end
end