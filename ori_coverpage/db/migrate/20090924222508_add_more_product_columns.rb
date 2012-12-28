class AddMoreProductColumns < ActiveRecord::Migration
  def self.up
    add_column :products, :publisher, :string, :limit => 128
    add_column :products, :imprint, :string, :limit => 128
    add_column :products, :annotation, :text
  end

  def self.down
    remove_column :products, :publisher
    remove_column :products, :imprint
    remove_column :products, :annotation
  end
end
