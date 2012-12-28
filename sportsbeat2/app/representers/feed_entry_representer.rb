module FeedEntryRepresenter
  include Roar::Representer::JSON::HAL

  property :id
  property :post_id
  property :iso8601

  link :delete do
    feed_entry_url self
  end
end