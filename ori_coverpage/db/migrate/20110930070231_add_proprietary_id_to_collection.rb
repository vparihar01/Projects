class AddProprietaryIdToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :proprietary_id, :string, :limit => 16
  end

  def self.down
    remove_column :collections, :proprietary_id
  end
end
