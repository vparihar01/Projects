class CreateCategoriesProducts < ActiveRecord::Migration
  def self.up 
    create_table :categories_products, :id => false do |t|
      t.column "category_id", :integer, :default => 0, :null => false
      t.column "product_id", :integer, :default => 0, :null => false
    end
    add_index :categories_products, ["product_id"], :name => "fk_cp_product"   
    
    Series.all.each do |x|
      execute("INSERT INTO categories_products (category_id, product_id) VALUES ('#{x.category_id}', '#{x.id}')")
    end   
  end

  def self.down 
    drop_table :categories_products
  end
end
