class CreateEditorialReviews < ActiveRecord::Migration
  def self.up
    create_table :editorial_reviews do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "written_on", :date
      t.column "body", :text, :default => "", :null => false
      t.column "source", :string, :limit => 128, :default => "", :null => false
    end

    create_table :editorial_reviews_products, :id => false do |t|
      t.column "editorial_review_id", :integer, :default => 0, :null => false
      t.column "product_id", :integer, :default => 0, :null => false
    end
    
    add_index :editorial_reviews_products, ["product_id"], :name => "fk_ep_product"
  end

  def self.down
    drop_table :editorial_reviews
    drop_table :editorial_reviews_products
  end
end
