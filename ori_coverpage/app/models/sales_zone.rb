class SalesZone < ActiveRecord::Base
  has_many :postal_codes
  has_many :contracts do
    def for_category(category)
      where('category = ?', category).first || 
      where('category = "All"').first
    end
  end
  has_many :sales_teams, :through => :contracts
  
  def to_s
    name
  end
  
  def postal_code_list(separator = ', ')
    postal_codes.collect(&:name).join(separator)
  end
  
  def postal_code_list=(codes)
    self.postal_codes = PostalCode.where( :name => codes.split(/,?\s+/) ).all
  end
end
