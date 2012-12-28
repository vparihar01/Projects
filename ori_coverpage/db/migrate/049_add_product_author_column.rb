class AddProductAuthorColumn < ActiveRecord::Migration
  def self.up
    add_column :products, :author, :string, :limit => 64
  end

  def self.down
    remove_column :products, :author
  end
end
