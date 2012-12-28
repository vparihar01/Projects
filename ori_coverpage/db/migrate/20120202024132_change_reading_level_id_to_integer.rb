class ChangeReadingLevelIdToInteger < ActiveRecord::Migration
  def self.up
    change_column :products, :reading_level_id, :integer
    remove_index :products, :name => 'index_products_on_reading_level'
  end

  def self.down
    change_column :products, :reading_level_id, :string
    add_index :products, :reading_level_id, :name => 'index_products_on_reading_level'
  end
end
