class Zone < ActiveRecord::Base
  has_many :postal_codes
  belongs_to :country
  INSTITUTION_TAX_EXEMPT_CODES = ['AZ', 'MN'].freeze # Zones that don't charge postal_code tax_rate on INSTITUTIONS

  def self.to_dropdown
    order("name").all.collect {|x| [x.name, x.id]}
  end
  
  def to_s
    self.name
  end
end
