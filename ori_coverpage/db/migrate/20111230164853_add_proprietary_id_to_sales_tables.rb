class AddProprietaryIdToSalesTables < ActiveRecord::Migration
  def self.up
    add_column :sales_teams, :proprietary_id, :string
    add_column :sales_zones, :proprietary_id, :string
  end

  def self.down
    remove_column :sales_teams, :proprietary_id
    remove_column :sales_zones, :proprietary_id
  end
end
