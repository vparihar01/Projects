class RemoveAssemblyIdColumnsFromProducts < ActiveRecord::Migration
  def self.up
    remove_column :products, :assembly_id
    remove_column :products, :sub_assembly_id
  end

  def self.down
    add_column :products, :assembly_id, :integer
    add_column :products, :sub_assembly_id, :integer
  end
end
