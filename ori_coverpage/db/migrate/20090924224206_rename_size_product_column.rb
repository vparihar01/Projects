class RenameSizeProductColumn < ActiveRecord::Migration
  def self.up
    rename_column :products, :size, :dimensions
  end

  def self.down
    rename_column :products, :dimensions, :size
  end
end
