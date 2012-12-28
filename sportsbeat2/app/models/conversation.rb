class Conversation < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'
  has_many :conversation_visibilities, :dependent => :destroy
  has_many :participants, :class_name => 'User', :through => :conversation_visibilities, :source => :user
  has_many :messages, :class_name => "ConversationMessage", :dependent => :destroy
  
  validate :at_least_two_participants?

  accepts_nested_attributes_for :messages

  def at_least_two_participants?
    if participants.length < 2
      errors[:base] << "a conversation must have at least two participants"
    end
  end

  def last_author
    self.messages.last.author if self.messages.count > 0
  end

  def recipients
    self.participants - [self.author]
  end
end
