class RemoveWeightAndDimensionsFromProducts < ActiveRecord::Migration
  def self.up
     remove_column :products, :weight
     remove_column :products, :dimensions
  end

  def self.down
    add_column :products, :weight, :decimal, :precision => 6, :scale => 2, :default => 0
    add_column :products, :dimensions, :string, :limit => 32
    execute("update products p
                set weight=(select weight from product_formats where product_id = p.id and format_id = 1),
                dimensions=(select dimensions from product_formats where product_id = p.id and format_id = 1)")
  end
end
