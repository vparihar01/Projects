module PostRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :edited_at
  property :content_html
  property :actor_display_name
  property :subject_display_name
  property :created_at
  property :activity_type
  property :activity,
    :class => Post,
    :extend => PostRepresenter,
    :if => lambda { activity_type == "Post" }

  link :self do
    post_url self
  end

  link :delete do
    if can? :destroy
      post_url self
    else
      nil
    end
  end

  link :actor do
    polymorphic_url actor if actor
  end

  link :subject do
    polymorphic_url subject if subject
  end
end
