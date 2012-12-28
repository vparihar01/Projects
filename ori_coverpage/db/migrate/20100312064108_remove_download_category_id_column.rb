class RemoveDownloadCategoryIdColumn < ActiveRecord::Migration
  def self.up
    remove_column :downloads, :download_category_id
  end

  def self.down
    add_column :downloads, :download_category_id, :integer
  end
end
