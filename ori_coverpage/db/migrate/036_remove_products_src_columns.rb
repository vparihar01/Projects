class RemoveProductsSrcColumns < ActiveRecord::Migration
  def self.up
    remove_column :products, :srcdiskid
    remove_column :products, :srcpoints
    remove_column :products, :srcreadlevel
    remove_column :products, :srclexile
  end

  def self.down
    add_column :products, :srcdiskid, :string, :limit => 8
    add_column :products, :srcpoints, :decimal, :precision => 3, :scale => 1
    add_column :products, :srcreadlevel, :decimal, :precision => 3, :scale => 1
    add_column :products, :srclexile, :integer, :limit => 4
  end 
end
