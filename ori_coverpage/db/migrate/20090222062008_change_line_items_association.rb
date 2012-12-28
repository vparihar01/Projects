class ChangeLineItemsAssociation < ActiveRecord::Migration
  def self.up
    add_column :line_items, :product_format_id, :integer, :null => false
    add_index :line_items, :product_format_id
    # get the product_format_id using the composite primary key (product_id, format_id)
    execute("update line_items set format_id=0 where format_id IS NULL;")
    execute("update line_items set product_format_id=(select id from product_formats where product_id=line_items.product_id and format_id=line_items.format_id);")
    remove_column :line_items, :product_id
    remove_column :line_items, :format_id
  end

  def self.down
    add_column :line_items, :product_id, :integer, :null => false
    add_column :line_items, :format_id, :integer, :null => false
    # get the product_id and format_id using the product_format_id association
    execute("update line_items set product_id=(select product_id from product_formats where id=line_items.product_format_id);")
    execute("update line_items set format_id=(select format_id from product_formats where id=line_items.product_format_id);")
    remove_column :line_items, :product_format_id
  end
end
