class LineItem < ActiveRecord::Base
  belongs_to :line_item_collection
  belongs_to :product_format
  
  before_save :calculate_total
  
  def product_name
    self.product_format.product.name
  end
  
  def format_id
    self.product_format.format_id
  end
  
  def format
    self.product_format.to_s
  end
  
  def product_id
    self.product_format.product_id
  end
  
  def product
    self.product_format.product
  end
  
  protected
  
    def calculate_total
      self.total_amount = self.unit_amount * self.quantity
    end
  
end