class PartialRegistration < ActiveRecord::Base
  validates :email, :presence => true
end