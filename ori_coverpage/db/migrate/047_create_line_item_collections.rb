class CreateLineItemCollections < ActiveRecord::Migration
  def self.up
    rename_table :carts, :line_item_collections
    rename_column :line_items, :cart_id, :line_item_collection_id
    rename_column :card_authorizations, :cart_id, :line_item_collection_id
    execute("update addresses set addressable_type = 'LineItemCollection' where addressable_type = 'Cart'")
    execute("update specs set specable_type = 'LineItemCollection' where specable_type = 'Cart'")
  end

  def self.down
    rename_table :line_item_collections, :carts
    rename_column :line_items, :line_item_collection_id, :cart_id
    rename_column :card_authorizations, :line_item_collection_id, :cart_id
    execute("update addresses set addressable_type = 'Cart' where addressable_type = 'LineItemCollection'")
    execute("update specs set specable_type = 'Cart' where specable_type = 'LineItemCollection'")
  end
end
