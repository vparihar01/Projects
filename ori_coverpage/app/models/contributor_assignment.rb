class ContributorAssignment < ActiveRecord::Base
  belongs_to :contributor
  belongs_to :product
  validates :product_id, :presence => true
  validates :contributor_id, :presence => true
  validates :role, :inclusion => { :in => APP_ROLES.keys }
  
  def to_s
    self.role
  end
  
end
