class AddCartTokens < ActiveRecord::Migration
  def self.up
    add_column :carts, :token, :string
    add_index :carts, :token
    
    add_column :line_items, :saved_for_later, :boolean
  end

  def self.down
    remove_column :carts, :token
    remove_column :line_items, :saved_for_later
  end
end
