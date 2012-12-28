class RemoveLineItemCollectionCustomerIdColumn < ActiveRecord::Migration
  def self.up
    execute("update line_item_collections set user_id = customer_id where user_id is null and customer_id is not null and type = 'Wishlist'")
    remove_column :line_item_collections, :customer_id
  end

  def self.down
    add_column :line_item_collections, :customer_id, :integer
    execute("update line_item_collections set customer_id = user_id where user_id is not null and type = 'Wishlist'")
  end
end
