class Customer < User
  has_many :posted_transactions, 
    :conditions => 'type not in ("Cart", "Quote")'
  has_many :addresses, :as => :addressable  
  has_many :sales
  
  validates :category, :presence => true # User model validates name, email
  
  INSTITUTIONS = ['School', 'Library'].freeze # A subset of CATEGORIES, that receive special discounts
  CATEGORIES = ['Individual', 'Retail', 'Wholesaler'].concat(INSTITUTIONS).freeze
  
  # returns the primary address, added to make 'find_contract' work
  def address
    self.addresses.where("is_primary = true").first
  end

  # replacement of ferret search
  # just searching for a given text (param[:q]) in the name and description fields using sql
  # issue #134
  def self.simple_search(params, per_page)
    self.where("name like '%#{params[:q]}%' or email like '%#{params[:q]}%'").paginate(:page => params[:page], :per_page => per_page)
  end
  
  def purchased_products(options = {})
    Product.purchased_by(self.id, options)
  end
  
  def find_contract
    if self.address && self.address.postal_code.sales_zone && self.address.postal_code.sales_zone.contracts
      self.address.postal_code.sales_zone.contracts.for_category(self.category)
    end
  end
end
