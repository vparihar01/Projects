class CreateCarts < ActiveRecord::Migration
  def self.up
    add_column :posted_transactions, :user_id, :integer
    add_column :posted_transactions, :name, :string # For quotes
    add_index :posted_transactions, :user_id
  end

  def self.down
    remove_column :posted_transactions, :user_id
    remove_column :posted_transactions, :name
  end
end
