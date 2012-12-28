class AddProductLanguageColumn < ActiveRecord::Migration
  def self.up
    add_column :products, :language, :string, :limit => 64
    update("UPDATE products SET language = 'English' WHERE type = 'Title'")
  end

  def self.down
    remove_column :products, :language
  end
end
