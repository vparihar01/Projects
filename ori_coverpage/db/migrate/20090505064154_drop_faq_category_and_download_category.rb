class DropFaqCategoryAndDownloadCategory < ActiveRecord::Migration
  def self.up
    drop_table :faq_categories
    drop_table :download_categories
  end

  def self.down
    create_table :faq_categories do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "name", :string, :default => "", :null => false
      t.column "description", :text
    end
    add_index :faq_categories, ["name"], :name => "idx_name"
    create_table :download_categories do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "name", :string, :default => "", :null => false
      t.column "description", :text
    end
    add_index :download_categories, ["name"], :name => "idx_name"
  end
end
