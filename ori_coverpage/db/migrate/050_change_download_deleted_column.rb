class ChangeDownloadDeletedColumn < ActiveRecord::Migration
  def self.up
    remove_column :downloads, :deleted_at
    add_column :downloads, :is_visible, :boolean, :default => true
  end

  def self.down
    add_column :downloads, :deleted_at, :datetime
    remove_column :downloads, :is_visible
  end
end
