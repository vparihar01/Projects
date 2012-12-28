class RemoveAndRenamePriceColumns < ActiveRecord::Migration
  def self.up
    rename_column :product_formats, :price_sl, :price
    remove_column :products, :price_sl
    remove_column :products, :price_list
    add_timestamps(:product_formats)
    add_timestamps(:products)
  end

  def self.down
    add_column :products, :price_sl, :decimal, :precision => 11, :scale => 2
    add_column :products, :price_list, :decimal, :precision => 11, :scale => 2
    Product.all.each do |p|
      p.update_attributes({:price_list => p.default_price_list, :price_sl => p.default_price})
    end
    rename_column :product_formats, :price, :price_sl
    remove_timestamps(:product_formats)
    remove_timestamps(:products)
  end
end
