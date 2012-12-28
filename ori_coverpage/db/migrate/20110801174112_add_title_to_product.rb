class AddTitleToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :title, :string
  end

  def self.down
    remove_column :products, :title
  end
end
