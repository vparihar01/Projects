class AddProductLexileColumns < ActiveRecord::Migration
  def self.up
    add_column :products, :word_count, :integer
    add_column :products, :lexile, :integer
  end

  def self.down
    remove_column :products, :word_count
    remove_column :products, :lexile
  end
end
