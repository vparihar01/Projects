class Invoice < PostedTransaction
  before_create :assign_contract
  
end