class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table :customers do |t|
      t.column :name, :string
      t.column :email, :string
      t.column :phone, :string
      t.column :type, :string
      t.column :searchable, :text
    end
    
    execute("insert into customers select id, name, email, phone, type, '' from users where type in ('wholesaler', 'library', 'school', 'retail', 'individual')")
    execute("delete from users where type in ('wholesaler', 'library', 'school', 'retail', 'individual')")
    
    add_index :customers, :type
    rename_column :posted_transactions, :sold_to, :customer_id
  end

  def self.down
    drop_table :customers
  end
end
