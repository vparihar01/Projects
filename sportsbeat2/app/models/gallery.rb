class Gallery < ActiveRecord::Base
  belongs_to :creator, :class_name => "User"
  belongs_to :owner, :polymorphic => true
  has_many :pictures

  validates :owner_id, :presence => true
  validates :owner_type, :inclusion => {:in => ['User', 'Team', 'GameTeam']}
  validates :name, :presence => true
  validates_uniqueness_of :name, :scope => [:owner_id, :owner_type]
end
