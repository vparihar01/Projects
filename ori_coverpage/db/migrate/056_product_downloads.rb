class ProductDownloads < ActiveRecord::Migration
  def self.up
    create_table :product_downloads do |t|
      t.column :content_type, :string
      t.column :filename, :string
      t.column :thumbnail, :string
      t.column :size, :integer
      t.column :parent_id, :integer
      t.column :product_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    create_table :product_downloads_users, :id => false do |t|
      t.column :product_download_id, :integer
      t.column :user_id, :integer
    end
    
    remove_column :products, :filename
  end

  def self.down
    drop_table :product_downloads
    drop_table :product_downloads_users
    add_column :products, :filename, :string
  end
end
