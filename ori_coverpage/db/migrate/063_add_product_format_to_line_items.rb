class AddProductFormatToLineItems < ActiveRecord::Migration
  def self.up
    add_column :line_items, :format_id, :integer
  end

  def self.down
    remove_column :line_items, :format_id
  end
end
