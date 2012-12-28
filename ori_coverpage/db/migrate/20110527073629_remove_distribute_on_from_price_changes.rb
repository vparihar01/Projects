class RemoveDistributeOnFromPriceChanges < ActiveRecord::Migration
  def self.up
    remove_column :price_changes, :distribute_on
  end

  def self.down
    add_column :price_changes, :distribute_on, :date
    execute("UPDATE price_changes SET distribute_on = DATE_SUB(implement_on, INTERVAL 90 DAY)")
    add_index :price_changes, :distribute_on
  end
end
