class SalesRep < User
  belongs_to :sales_team
  
  before_create :assign_managed_team
  
  protected
  
    def assign_managed_team
      self.managed_team = self.sales_team unless self.sales_team.head_sales_rep
    end
    
end