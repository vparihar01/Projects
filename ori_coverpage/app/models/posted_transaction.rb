class PostedTransaction < ActiveRecord::Base
  belongs_to :sales_team
  has_many :posted_transaction_lines
  belongs_to :customer
  belongs_to :contract
  
  def assign_contract
    self.contract = self.customer.find_contract
  end
  
  def commission
    self.commission_rate * self.amount
  end
  
  def commission_rate
    self.contract ? self.contract.rate : 0
  end
end
