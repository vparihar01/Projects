class FixProductDownloadsAssociation < ActiveRecord::Migration
  def self.up
    rename_column :product_downloads, :product_id, :title_id
  end

  def self.down
    rename_column :product_downloads, :title_id, :product_id
  end
end
