class AddProductsEisbnColumn < ActiveRecord::Migration
  def self.up
    add_column :products, :eisbn, :string
  end

  def self.down
    remove_column :products, :eisbn
  end
end
