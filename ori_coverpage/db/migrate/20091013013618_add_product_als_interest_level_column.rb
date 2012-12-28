class AddProductAlsInterestLevelColumn < ActiveRecord::Migration
  def self.up
    add_column :products, :alsinterestlevel, :string, :limit => 32
  end

  def self.down
    remove_column :products, :alsinterestlevel
  end
end
