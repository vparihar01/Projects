class Quote < LineItemCollection
  belongs_to :customer
  belongs_to :sales_team
  
  validates :name, :presence => true
  
  before_create :assign_team
  
  def copy_to_quote
    new_quote = self.clone
    new_quote.name = "Copy of #{self.name}"
    new_quote.save
    self.line_items.each do |item|
      new_quote.line_items << item.clone
    end
    new_quote
  end
  
  protected
  
    def assign_team
      self.sales_team = self.user.sales_team if self.user
    end
end
