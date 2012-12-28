class PolymorphicAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :addressable_type, :string
    rename_column :addresses, :user_id, :addressable_id

    execute("update addresses a, customers c set a.addressable_type = 'Customer' where a.addressable_id = c.id and a.addressable_type is null")
    execute("update addresses a, users u set a.addressable_type = 'User' where a.addressable_id = u.id and a.addressable_type is null")
  end
  
  PostedTransaction.all.each {|t| t.assign_contract && t.save rescue nil; }

  def self.down
    remove_column :addresses, :addressable_type
    rename_column :addresses, :addressable_id, :user_id
  end
end
