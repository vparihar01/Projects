require 'canner'

module FeedRepresenter
  include Roar::Representer::JSON::HAL

  property :name

  collection :entries,
    :class => FeedEntry,
    :extend => FeedEntryRepresenter,
    :embedded => true

  collection :posts,
    :class => Post,
    :extend => PostRepresenter,
    :embedded => true

  link :self do
    self[:self_url]
  end

  link :newer do
    self[:newer_url]
  end

  link :older do
    self[:older_url]
  end

  link :owner do
    polymorphic_url self[:owner]
  end

  def name
    self[:name]
  end

  def entries
    self[:entries].map{|e| Canner.new(e, self.ability)}
  end

  def posts
    Post.where(:id => self[:entries].map(&:post_id)).order("created_at desc").map{|p| Canner.new(p, ability)}
  end
end
