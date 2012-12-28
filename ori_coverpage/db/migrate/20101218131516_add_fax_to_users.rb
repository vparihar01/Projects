class AddFaxToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :fax, :string, :limit => 40
  end

  def self.down
    remove_column :users, :fax
  end
end
