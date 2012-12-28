class AddProprietaryIdColumns < ActiveRecord::Migration
  def self.up
    add_column :testimonials, :proprietary_id, :string, :limit => 16
    add_column :contributors, :proprietary_id, :string, :limit => 16
    add_column :links, :proprietary_id, :string, :limit => 16
    add_column :editorial_reviews, :proprietary_id, :string, :limit => 16
  end

  def self.down
    remove_column :testimonials, :proprietary_id
    remove_column :contributors, :proprietary_id
    remove_column :links, :proprietary_id
    remove_column :editorial_reviews, :proprietary_id
  end
end
