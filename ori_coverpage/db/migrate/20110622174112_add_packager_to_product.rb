class AddPackagerToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :packager, :string, :limit => 64
  end

  def self.down
    remove_column :products, :packager
  end
end
