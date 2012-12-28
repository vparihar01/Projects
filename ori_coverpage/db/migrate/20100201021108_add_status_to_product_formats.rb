class AddStatusToProductFormats < ActiveRecord::Migration
  def self.up
    add_column :product_formats, :status, :string, :limit => 4, :default => 'NYP', :null => false
  end

  def self.down
    remove_column :product_formats, :status
  end
end
