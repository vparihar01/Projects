class AddIsSpotlightToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :is_spotlight, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :products, :is_spotlight
  end
end
