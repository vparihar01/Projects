class CreateCatalogRequests < ActiveRecord::Migration
  def self.up
    create_table :catalog_requests do |t|
      t.column :created_at, :datetime
      t.column :is_processed, :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :catalog_requests
  end
end
