class AddAlsquizAmountInCentsToLineItemCollection < ActiveRecord::Migration
  def self.up
    add_column :line_item_collections, :alsquiz_amount_in_cents, :integer
  end

  def self.down
    remove_column :line_item_collections, :alsquiz_amount_in_cents
  end
end
