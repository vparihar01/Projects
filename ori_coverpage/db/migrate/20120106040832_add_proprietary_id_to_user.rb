class AddProprietaryIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :proprietary_id, :string
  end

  def self.down
    remove_column :users, :proprietary_id
  end
end
