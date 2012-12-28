class AddParentIdToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :parent_id, :integer
    Collection.reset_column_information
    Collection.set_tree
  end

  def self.down
    remove_column :collections, :parent_id
  end
end
