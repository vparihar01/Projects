class CreateDownloads < ActiveRecord::Migration
  def self.up
    create_table :downloads do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "title", :string, :limit => 128
      t.column "file_name", :string, :limit => 128
      t.column "description", :string, :limit => 128
      t.column "views", :integer, :default => 0, :null => false
      t.column "download_category_id", :integer
    end
    
    create_table :download_categories do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "name", :string, :default => "", :null => false
      t.column "description", :text
    end

    add_index :download_categories, ["name"], :name => "idx_name"
  end

  def self.down
    drop_table :downloads
    drop_table :download_categories
  end
end
