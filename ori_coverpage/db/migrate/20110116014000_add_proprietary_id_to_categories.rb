class AddProprietaryIdToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :proprietary_id, :string, :limit => 16
  end

  def self.down
    remove_column :categories, :proprietary_id
  end
end
