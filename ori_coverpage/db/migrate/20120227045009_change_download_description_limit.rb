class ChangeDownloadDescriptionLimit < ActiveRecord::Migration
  def self.up
    change_column :downloads, :description, :string, :limit => 255
  end

  def self.down
    change_column :downloads, :description, :string, :limit => 128
  end
end
