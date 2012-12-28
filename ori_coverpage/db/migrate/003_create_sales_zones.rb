class CreateSalesZones < ActiveRecord::Migration
  def self.up
    create_table :sales_zones do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :sales_team_id, :integer
      t.column :contact_type, :string
    end
  end

  def self.down
    drop_table :sales_zones
  end
end
