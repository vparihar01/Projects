class AddCartProcessingColumn < ActiveRecord::Migration
  def self.up
    add_column :carts, :processing_amount_in_cents, :integer, :default => 0
  end

  def self.down
    remove_column :carts, :processing_amount_in_cents
  end
end
