class AddCustomerIdToLineItemCollection < ActiveRecord::Migration
  def self.up
    add_column :line_item_collections, :customer_id, :integer
  end

  def self.down
    remove_column :line_item_collections, :customer_id
  end
end
