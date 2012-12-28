class Category < ActiveRecord::Base
  has_and_belongs_to_many :products, :uniq => true, :order => "name"
  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
  
  # Change routing. Use name not id.
  def to_param 
    "#{id}-#{name.gsub(/[^a-z1-9]+/i, '-').downcase}" 
  end

  scope :visible, where("is_visible = ?", true)

  def self.set_visibility
    all.each do |category|
      category.update_attribute(:is_visible, (category.products.available.count > 0))
    end
  end
end
