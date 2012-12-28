class CartSaleAttributes < ActiveRecord::Migration
  def self.up
    add_column :carts, :tax_in_cents, :integer, :default => 0
    add_column :carts, :payment_method, :string, :length => 20
    add_column :carts, :comments, :text
    add_column :carts, :spec_id, :integer
    add_column :carts, :completed_at, :datetime
  end

  def self.down
    remove_column :carts, :tax_in_cents
    remove_column :carts, :payment_method
    remove_column :carts, :comments
    remove_column :carts, :spec_id
    remove_column :carts, :completed_at
  end
end
