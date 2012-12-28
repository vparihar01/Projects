class SupportContact < ActiveRecord::Base
  belongs_to :user
  belongs_to :handler, :class_name => "User"

  validates :text, :presence => true
  validates :kind, :inclusion => {:in => ["abuse", "other"]}
  validate :return_information

  def mark_handled_by user
    self.handled = true
    self.handler = user
    self.handled_at = DateTime.now
  end

  def return_information
    if !(self.user || self.email)
      errors[:base] = "Message has no return information"
    end
  end
end