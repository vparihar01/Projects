class Picture < ActiveRecord::Base
  attr_accessible :file
  mount_uploader :file, PictureUploader

  belongs_to :owner, :class_name => "User"
  belongs_to :gallery

  has_one :featured_item, :as => 'Item', :dependent => :destroy
  has_many :comments, :as => :commentable, :dependent => :destroy

  validates :owner_id, :presence => true
  validates :gallery_id, :presence => true
  validates :file, :presence => true
end
