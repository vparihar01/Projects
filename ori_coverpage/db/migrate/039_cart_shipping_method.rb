class CartShippingMethod < ActiveRecord::Migration
  def self.up
    add_column :carts, :shipping_amount_in_cents, :integer, :default => 0
    add_column :carts, :shipping_method, :string, :limit => 2
    add_column :carts, :weight, :decimal, :precision => 6, :scale => 2, :default => 0
    add_column :products, :weight, :decimal, :precision => 6, :scale => 2, :default => 0
  end

  def self.down
    remove_column :carts, :shipping_amount_in_cents
    remove_column :carts, :shipping_method
    remove_column :carts, :weight
    remove_column :products, :weight
  end
end
