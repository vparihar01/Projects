class Comment < ActiveRecord::Base
  belongs_to :author, :class_name => "User"
  belongs_to :commentable, :polymorphic => true

  validates :user, :presence => true
  validates :content, :presence => true
  validates :content_html, :presence => true

  auto_html_for :content do
    html_escape
    image
    link :target => "_blank", :rel => "nofollow"
    simple_format
  end
end