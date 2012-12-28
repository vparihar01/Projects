class Subscription < ActiveRecord::Base
  belongs_to :subscriber, :class_name => "User"
  belongs_to :subscribable, :polymorphic => true

  validates :subscribable, :presence => true
  validate :no_self_subscription

  def no_self_subscription
    if subscribable_type == 'User' && subscribable_id == subscriber_id
      errors[:base] << 'cannot subscribe to yourself'
    end
  end
end
