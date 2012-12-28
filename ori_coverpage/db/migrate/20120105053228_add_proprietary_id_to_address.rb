class AddProprietaryIdToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :proprietary_id, :string
  end

  def self.down
    remove_column :addresses, :proprietary_id
  end
end
