class CreateProducts < ActiveRecord::Migration
  def self.up
    require 'importer'
    
    create_table :products do |t|
      t.column :name, :string
      t.column :isbn, :string
      t.column :isbn_code, :string
      t.column :price_list_in_cents, :integer
      t.column :price_sl_in_cents, :integer
      t.column :is_book, :boolean
      t.column :is_wholesale, :boolean
      t.column :is_inventory, :boolean
    end
    
    #Importer.import_products('products.mer', true)
  end

  def self.down
    drop_table :products
  end
end
