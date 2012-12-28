class RemoveProductsIsbnCodeColumn < ActiveRecord::Migration
  def self.up
    remove_column :products, :isbn_code
  end

  def self.down
    add_column :products, :isbn_code, :string    
  end
end
