class AddHasValidIsbnToFormat < ActiveRecord::Migration
  def self.up
    add_column :formats, :requires_valid_isbn, :boolean, :default => 1, :null => false
  end

  def self.down
    remove_column :formats, :requires_valid_isbn
  end
end
