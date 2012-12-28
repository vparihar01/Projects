class ConversationVisibility < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :user

  validates :conversation_id, :presence => true
  validates :user_id, :presence => true
  validates :participants, :presence => true, :numericality => { :greater_than => 1 }
end
