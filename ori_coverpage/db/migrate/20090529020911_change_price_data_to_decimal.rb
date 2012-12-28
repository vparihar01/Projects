class ChangePriceDataToDecimal < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    decimalize_data(LineItemCollection, :amount)
    decimalize_data(LineItemCollection, :shipping_amount)
    decimalize_data(LineItemCollection, :tax)
    decimalize_data(LineItemCollection, :processing_amount)
    decimalize_data(LineItemCollection, :alsquiz_amount)
    decimalize_data(LineItem, :unit_amount)
    decimalize_data(LineItem, :total_amount)
    decimalize_data(PostedTransactionLine, :unit_amount)
    decimalize_data(PostedTransactionLine, :total_amount)
    decimalize_data(PostedTransactionLine, :rep_base)
    decimalize_data(PostedTransaction, :amount)
    decimalize_data(PostedTransaction, :ship_amount)
    decimalize_data(PostedTransaction, :ship_sale_amount)
    decimalize_data(PostedTransaction, :transaction_amount)
    decimalize_data(PostedTransaction, :tax)
    decimalize_data(PostedTransaction, :rep_base)
    decimalize_data(ProductFormat, :price_list)
    decimalize_data(ProductFormat, :price_sl)
    decimalize_data(Product, :price_list)
    decimalize_data(Product, :price_sl)
    decimalize_data(SalesTarget, :amount)
    LineItemCollection.all.each {|x| x.update_amount!}
  end

  def self.down
    undecimalize_data(LineItemCollection, :amount)
    undecimalize_data(LineItemCollection, :shipping_amount)
    undecimalize_data(LineItemCollection, :tax)
    undecimalize_data(LineItemCollection, :processing_amount)
    undecimalize_data(LineItemCollection, :alsquiz_amount)
    undecimalize_data(LineItem, :unit_amount)
    undecimalize_data(LineItem, :total_amount)
    undecimalize_data(PostedTransactionLine, :unit_amount)
    undecimalize_data(PostedTransactionLine, :total_amount)
    undecimalize_data(PostedTransactionLine, :rep_base)
    undecimalize_data(PostedTransaction, :amount)
    undecimalize_data(PostedTransaction, :ship_amount)
    undecimalize_data(PostedTransaction, :ship_sale_amount)
    undecimalize_data(PostedTransaction, :transaction_amount)
    undecimalize_data(PostedTransaction, :tax)
    undecimalize_data(PostedTransaction, :rep_base)
    undecimalize_data(ProductFormat, :price_list)
    undecimalize_data(ProductFormat, :price_sl)
    undecimalize_data(Product, :price_list)
    undecimalize_data(Product, :price_sl)
    undecimalize_data(SalesTarget, :amount)
    LineItemCollection.all.each {|x| x.update_amount!}
  end
end
