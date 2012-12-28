class AddAddressIsPrimaryColumn < ActiveRecord::Migration
  def self.up
    add_column :addresses, :is_primary, :boolean, :default => false, :null => false   
    Address.update_all("is_primary = true")
  end

  def self.down
    remove_column :addresses, :is_primary
  end
end  
