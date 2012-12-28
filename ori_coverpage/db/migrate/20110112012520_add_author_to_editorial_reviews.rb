class AddAuthorToEditorialReviews < ActiveRecord::Migration
  def self.up
    add_column :editorial_reviews, :author, :string, :limit => 128
  end

  def self.down
    remove_column :editorial_reviews, :author
  end
end
