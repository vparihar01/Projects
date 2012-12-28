class AddStatusToLineItemCollection < ActiveRecord::Migration
  def self.up
    add_column :line_item_collections, :status, :string
  end

  def self.down
    remove_column :line_item_collections, :status
  end
end
