class PostedTransactionLine < ActiveRecord::Base
  belongs_to :posted_transaction
  belongs_to :product
end
