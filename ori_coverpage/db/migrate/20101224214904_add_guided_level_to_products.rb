class AddGuidedLevelToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :guided_level, :string, :limit => 4
  end

  def self.down
    remove_column :products, :guided_level
  end
end
