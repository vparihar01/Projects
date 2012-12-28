class RenameBindingColumn < ActiveRecord::Migration
  def self.up
    rename_column :products, :binding, :binding_type
  end

  def self.down
    rename_column :products, :binding_type, :binding
  end
end
