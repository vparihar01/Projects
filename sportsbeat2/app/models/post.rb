require 'commentable'

class Post < ActiveRecord::Base
  include Commentable

  belongs_to :actor, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  belongs_to :activity, :polymorphic => true
  has_many :feed_entries, :dependent => :destroy

  validates :actor, :presence => true
  validates :content, :length => { :maximum => 1024 }
  validates :subject, :presence => true
  validate :has_text_or_activity?, :on => :create

  before_save :sanitize_content
  before_save :set_display_names

  # Auto HTML-ize links in the post body
  auto_html_for :content do
    html_escape
    image
    youtube(:width => 350, :height => 240, :wmode => :transparent)
    link :target => "_blank", :rel => "nofollow"
    simple_format
  end

  def destination_feeds
    feeds = Set.new

    if subject.class == User
      feeds << [subject, 'beat']
      feeds << [subject, 'news']
      feeds << [actor, 'beat']
      feeds << [actor, 'news']

      if actor.class == User
        actor.teammates.each { |t| feeds << [t, 'news'] }
        #user.subscriptions_to_me.map(&:user_id).each { |s| feeds << ['User', s, 'news'] }
      end

    elsif subject.class == GameTeam
      feeds << [author, 'beat']

      if actor.class == User
        actor.teammate_ids.each { |t| feeds << [t, 'news'] }
        #user.subscriptions_to_me.map(&:user_id).each { |s| feeds << ['User', s, 'news'] }
      end

      if subject.home
        feeds << [subject.game, 'home']
      else
        feeds << [subject.game, 'away']
      end
    end

    return feeds
  end

  def has_text_or_activity?
    if content.blank? && activity.nil?
      errors[:base] << 'This appears to be an empty post'
    end
  end

  def push_to_feeds!
    feeds = destination_feeds
    FeedEntry.transaction do
      feeds.each do |f|
        e = FeedEntry.new
        e.owner = f[0]
        e.name = f[1]
        e.post = self
        e.save!
      end
    end
  end

  def sanitize_content
    self.content = Sanitize.clean(content)
  end

  def shared= b
    write_attribute(:shared, b)

    if b && proxy_comments
      write_attribute(:proxy_comments, false)
    end
  end

  def set_display_names
    if actor.respond_to? :display_name
      self.actor_display_name = actor.display_name
    else
      self.actor_display_name = actor.class.name + actor.id.to_s
    end

    if subject.respond_to? :display_name
      self.subject_display_name = subject.display_name
    else
      self.subject_display_name = subject.class.name + subject.id.to_s
    end
  end
end
