class AddIsVisibleToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :is_visible, :boolean, :default => false
    Category.reset_column_information
    Category.all.each do |c|
      c.update_attribute(:is_visible, (c.products.available.count > 0))
    end
  end

  def self.down
    remove_column :categories, :is_visible
  end
end
