class RemoveProductsIsInventoryColumn < ActiveRecord::Migration
  def self.up
    remove_column :products, :is_inventory
  end

  def self.down
    add_column :products, :is_inventory, :boolean
    execute("UPDATE products SET is_inventory = 1 WHERE type = 'Title'")
  end
end
