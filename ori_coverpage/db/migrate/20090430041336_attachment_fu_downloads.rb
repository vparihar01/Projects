class AttachmentFuDownloads < ActiveRecord::Migration
  def self.up
    add_column :downloads, :size, :integer
    add_column :downloads, :content_type, :string
    rename_column :downloads, :file_name, :filename
  end

  def self.down
    remove_column :downloads, :size
    remove_column :downloads, :content_type
    rename_column :downloads, :file_name, :filename
  end
end
