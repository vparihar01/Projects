class RevertCustomers < ActiveRecord::Migration
  def self.up
    add_column :users, :category, :string
    
    execute("insert ignore into users (id, name, email, phone, type, category) select id, name, email, phone, 'Customer', type from customers")
    execute("update addresses set addressable_type = 'User' where addressable_type = 'Customer'")
    execute("update users set category = type, type = 'Customer'  where type not in ('SalesRep', 'Admin')")
    
    drop_table :customers
    
    FileUtils.rm_rf(Rails.root.join('index')) # Whack the ferret index
  end

  def self.down
    create_table :customers do |t|
      t.column :name, :string
      t.column :email, :string
      t.column :phone, :string
      t.column :type, :string
    end
    
    execute("insert into customers select id, name, email, phone, category from users where category in ('wholesaler', 'library', 'school', 'retail', 'individual')")
    execute("delete from users where category in ('wholesaler', 'library', 'school', 'retail', 'individual')")
    
    add_index :customers, :type
    remove_column :users, :category
    
    FileUtils.rm_rf(Rails.root.join('index')) # Whack the ferret index
  end
end
