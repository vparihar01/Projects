class AssociateStatusChangeToSale < ActiveRecord::Migration
  def self.up
    rename_column :status_changes, :line_item_collection_id, :sale_id
  end

  def self.down
    rename_column :status_changes, :sale_id, :line_item_collection_id
  end
end
