class AddCollectionDescriptionColumn < ActiveRecord::Migration
  def self.up
    add_column :collections, :description, :text
    add_column :collections, :released_on, :date
  end

  def self.down
    remove_column :collections, :description
    remove_column :collections, :released_on
  end
end
