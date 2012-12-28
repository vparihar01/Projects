class RenameTextbylineProductColumn < ActiveRecord::Migration
  def self.up
    rename_column :products, :textbyline, :subtitle
    rename_column :products, :textspotlight, :spotlight_description
  end

  def self.down
    rename_column :products, :subtitle, :textbyline
    rename_column :products, :spotlight_description, :textspotlight
  end
end
