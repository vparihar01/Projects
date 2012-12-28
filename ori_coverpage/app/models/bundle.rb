class Bundle < Discount

  has_and_belongs_to_many :products, :uniq => true
  validates :products, :presence => true
    
  def matches_products?(product_ids)
    return false unless self.product_ids.any?
    (self.product_ids & product_ids).eql?(self.product_ids)
  end
  
  def self.for_products(product_ids, code = nil)
    all.select do |bundle|
      bundle.available? && bundle.matches_products?(product_ids) && bundle.matches_code?(code)
    end
  end
  
  def matches_code?(match_code)
    self.code.blank? || self.code == match_code
  end
  
end
