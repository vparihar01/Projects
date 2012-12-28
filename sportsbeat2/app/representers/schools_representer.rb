module SchoolsRepresenter
  include Roar::Representer::JSON::HAL

  collection :schools,
    :class => School,
    :extend => SchoolRepresenter,
    :embedded => true

  link :self do
    schools_url
  end

  def schools
    self
  end
end