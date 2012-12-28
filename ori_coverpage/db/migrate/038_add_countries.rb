class AddCountries < ActiveRecord::Migration
  def self.up
    add_column :addresses, :country_id, :integer
  end

  def self.down
    remove_column :addresses, :country
  end
end
