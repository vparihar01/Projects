class CreatePriceChanges < ActiveRecord::Migration
  def self.up
    create_table :price_changes do |t|
      t.integer :product_format_id, :null => false
      t.decimal :price_list, :precision => 11, :scale => 2, :null => false
      t.decimal :price, :precision => 11, :scale => 2, :null => false
      t.date :distribute_on
      t.date :implement_on
      t.string :state, :default => 'new', :null => false

      t.timestamps
    end

    add_index :price_changes, :distribute_on
    add_index :price_changes, :implement_on
    add_index :price_changes, :state
  end

  def self.down
    drop_table :price_changes
  end
end
