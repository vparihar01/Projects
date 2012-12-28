class AddTitleToEditorialReviews < ActiveRecord::Migration
  def self.up
    add_column :editorial_reviews, :title, :string
  end

  def self.down
    remove_column :editorial_reviews, :title, :string
  end
end
