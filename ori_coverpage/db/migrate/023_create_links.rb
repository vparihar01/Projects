class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.column "title", :string, :limit => 128
      t.column "description", :text
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "url", :string
      t.column "is_kids", :boolean
      t.column "is_adults", :boolean
      t.column "is_highlight", :boolean
      t.column "views", :integer, :default => 0, :null => false
      t.column "code", :integer, :limit => 3
      t.column "redirect", :string
      t.column "meta_title", :string, :limit => 128
      t.column "meta_description", :text
    end

    create_table :links_products, :id => false do |t|
      t.column "link_id", :integer, :default => 0, :null => false
      t.column "product_id", :integer, :default => 0, :null => false
    end

    add_index :links_products, ["product_id"], :name => "fk_lp_product"
  end

  def self.down
    drop_table :links
    drop_table :links_products
  end
end
