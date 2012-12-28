class CatalogRequest < ActiveRecord::Base
  has_one :address, :as => :addressable, :dependent => :delete
  accepts_nested_attributes_for :address

  validates_associated :address
  validate :has_address
    
  def zone_name
    self.address.zone_name
  end
  
  def postal_code_name
    self.address.postal_code_name
  end
  
  def country_name
    self.address.country_name
  end

  private
    def has_address
      errors.add(:base,"Address missing") if self.address.nil?
    end
    
end
