class AddAvailableProductsCounterToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :available_products_counter, :integer, :default => 0
    Collection.reset_column_information
    Collection.all.each do |c|
      Collection.update_counters c.id, :available_products_counter => c.products.available.count
    end
  end

  def self.down
    remove_column :collections, :available_products_counter
  end
end
