class AddAbbreviationToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :abbreviation, :string, :limit => 64
  end

  def self.down
    remove_column :categories, :abbreviation
  end
end
