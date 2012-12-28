class AddLocColumns < ActiveRecord::Migration
  def self.up
    add_column :products, :cip, :text
    add_column :products, :lccn, :string, :limit => 32
    add_column :products, :lcclass, :string, :limit => 32
  end

  def self.down
    remove_column :products, :cip
    remove_column :products, :lccn
    remove_column :products, :lcclass
  end
end
