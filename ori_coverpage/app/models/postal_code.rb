class PostalCode < ActiveRecord::Base
  belongs_to :zone
  has_many :addresses
  belongs_to :sales_zone
  
  validates :name, :presence => true, :uniqueness => true
  validates :zone_id, :presence => true
  
  def to_s
    "#{self.zone.nil? ? "" : self.zone.code}  #{self.name}"
  end
end