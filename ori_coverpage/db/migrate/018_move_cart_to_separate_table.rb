class MoveCartToSeparateTable < ActiveRecord::Migration
  def self.up
    create_table :carts do |t|
      t.column :amount_in_cents, :integer, :default => 0
      t.column :user_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :type, :string, :default => 'Cart'
      t.column :name, :string # For named quotes
      t.column :customer_id, :integer
      t.column :sales_team_id, :integer
    end
    
    create_table :line_items do |t|
      t.column :cart_id, :integer
      t.column :product_id, :integer
      t.column :quantity, :integer, :default => 0
      t.column :unit_amount_in_cents, :integer, :default => 0
      t.column :total_amount_in_cents, :integer, :default => 0
    end
    
    add_index :carts, :type
    add_index :carts, :user_id
    add_index :carts, :created_at
    
    add_index :line_items, :cart_id
    add_index :line_items, :product_id
    
    remove_column :posted_transactions, :user_id
    remove_column :posted_transactions, :name
    
  end

  def self.down
    drop_table :carts
    drop_table :line_items
    
    add_column :posted_transactions, :user_id, :integer
    add_column :posted_transactions, :name, :string # For quotes
    add_index :posted_transactions, :user_id
  end
end
