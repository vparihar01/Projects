class AddTocToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :toc, :text
  end

  def self.down
    remove_column :products, :toc
  end
end
