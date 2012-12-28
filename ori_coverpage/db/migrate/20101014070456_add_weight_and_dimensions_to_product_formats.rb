class AddWeightAndDimensionsToProductFormats < ActiveRecord::Migration
  def self.up
    add_column :product_formats, :weight, :decimal, :precision => 6, :scale => 2, :default => 0
    add_column :product_formats, :dimensions, :string, :limit => 32
    execute("update product_formats pf
                set weight=(select weight from products where id = pf.product_id),
                dimensions=(select dimensions from products where id = pf.product_id)
             where format_id = 1")
  end

  def self.down
    remove_column :product_formats, :dimensions
    remove_column :product_formats, :weight
  end
end
