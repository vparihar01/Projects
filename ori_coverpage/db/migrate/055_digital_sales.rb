class DigitalSales < ActiveRecord::Migration
  def self.up
    add_column :products, :filename, :string
    
    create_table :products_users, :id => false do |t|
      t.column :product_id, :integer
      t.column :user_id, :integer
    end
    
    add_index :products_users, :user_id
  end

  def self.down
    remove_column :products, :filename
    drop_table :products_users
  end
end
