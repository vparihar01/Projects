class ConversationMessage < ActiveRecord::Base
  belongs_to :author, :class_name => "User"
  belongs_to :conversation, :touch => true
  validates :text, :length => {:minimum => 1}
end