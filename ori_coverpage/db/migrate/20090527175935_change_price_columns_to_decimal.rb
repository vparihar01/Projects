class ChangePriceColumnsToDecimal < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    decimalize_column(LineItemCollection, :amount_in_cents, :amount)
    decimalize_column(LineItemCollection, :shipping_amount_in_cents, :shipping_amount)
    decimalize_column(LineItemCollection, :tax_in_cents, :tax)
    decimalize_column(LineItemCollection, :processing_amount_in_cents, :processing_amount)
    decimalize_column(LineItemCollection, :alsquiz_amount_in_cents, :alsquiz_amount)
    decimalize_column(LineItem, :unit_amount_in_cents, :unit_amount)
    decimalize_column(LineItem, :total_amount_in_cents, :total_amount)
    decimalize_column(PostedTransactionLine, :unit_amount_in_cents, :unit_amount)
    decimalize_column(PostedTransactionLine, :total_amount_in_cents, :total_amount)
    decimalize_column(PostedTransactionLine, :rep_base_in_cents, :rep_base)
    decimalize_column(PostedTransaction, :amount_in_cents, :amount)
    decimalize_column(PostedTransaction, :ship_amount_in_cents, :ship_amount)
    decimalize_column(PostedTransaction, :ship_sale_amount_in_cents, :ship_sale_amount)
    decimalize_column(PostedTransaction, :transaction_amount_in_cents, :transaction_amount)
    decimalize_column(PostedTransaction, :tax_in_cents, :tax)
    decimalize_column(PostedTransaction, :rep_base_in_cents, :rep_base)
    decimalize_column(ProductFormat, :price_list_in_cents, :price_list)
    decimalize_column(ProductFormat, :price_sl_in_cents, :price_sl)
    decimalize_column(Product, :price_list_in_cents, :price_list)
    decimalize_column(Product, :price_sl_in_cents, :price_sl)
    decimalize_column(SalesTarget, :amount_in_cents, :amount)
  end

  def self.down
    undecimalize_column(LineItemCollection, :amount_in_cents, :amount)
    undecimalize_column(LineItemCollection, :shipping_amount_in_cents, :shipping_amount)
    undecimalize_column(LineItemCollection, :tax_in_cents, :tax)
    undecimalize_column(LineItemCollection, :processing_amount_in_cents, :processing_amount)
    undecimalize_column(LineItemCollection, :alsquiz_amount_in_cents, :alsquiz_amount)
    undecimalize_column(LineItem, :unit_amount_in_cents, :unit_amount)
    undecimalize_column(LineItem, :total_amount_in_cents, :total_amount)
    undecimalize_column(PostedTransactionLine, :unit_amount_in_cents, :unit_amount)
    undecimalize_column(PostedTransactionLine, :total_amount_in_cents, :total_amount)
    undecimalize_column(PostedTransactionLine, :rep_base_in_cents, :rep_base)
    undecimalize_column(PostedTransaction, :amount_in_cents, :amount)
    undecimalize_column(PostedTransaction, :ship_amount_in_cents, :ship_amount)
    undecimalize_column(PostedTransaction, :ship_sale_amount_in_cents, :ship_sale_amount)
    undecimalize_column(PostedTransaction, :transaction_amount_in_cents, :transaction_amount)
    undecimalize_column(PostedTransaction, :tax_in_cents, :tax)
    undecimalize_column(PostedTransaction, :rep_base_in_cents, :rep_base)
    undecimalize_column(ProductFormat, :price_list_in_cents, :price_list)
    undecimalize_column(ProductFormat, :price_sl_in_cents, :price_sl)
    undecimalize_column(Product, :price_list_in_cents, :price_list)
    undecimalize_column(Product, :price_sl_in_cents, :price_sl)
    undecimalize_column(SalesTarget, :amount_in_cents, :amount)
  end
end
