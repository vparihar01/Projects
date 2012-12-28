class ChangeBisacRelationship < ActiveRecord::Migration
  def self.up
    rename_column :bisac_assignments, :title_id, :product_id
  end

  def self.down
    rename_column :bisac_assignments, :product_id, :title_id
  end
end
