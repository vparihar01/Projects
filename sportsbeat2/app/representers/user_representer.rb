module UserRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :first_name
  property :last_name
  property :display_name

  link :self do
    user_url self
  end
end