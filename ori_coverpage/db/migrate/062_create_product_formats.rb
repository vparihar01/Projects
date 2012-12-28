class CreateProductFormats < ActiveRecord::Migration
  def self.up
    create_table :product_formats do |t|
      t.column :product_id, :integer, :null => false
      t.column :format_id, :integer, :limit => 2
      t.column :price_list_in_cents, :integer
      t.column :price_sl_in_cents, :integer
    end
    # index by products
    add_index :product_formats, :product_id, :unique => false, :name => "formats_by_products"
    add_index :product_formats, [:product_id, :format_id], :unique => true, :name => "products_formats"

    # create a paper_format record for each product in DB
    execute("insert into product_formats(product_id, format_id, price_list_in_cents, price_sl_in_cents) select id, 0, price_list_in_cents, price_sl_in_cents from products;")
  end

  def self.down
    drop_table :product_formats
  end
end
