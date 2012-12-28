class AddProductFeatureColumns < ActiveRecord::Migration
  def self.up
    add_column :products, :has_index, :boolean
    add_column :products, :has_bibliography, :boolean
    add_column :products, :has_glossary, :boolean
    add_column :products, :has_sidebars, :boolean
    add_column :products, :has_table_of_contents, :boolean
  end

  def self.down
    remove_column :products, :has_index
    remove_column :products, :has_bibliography
    remove_column :products, :has_glossary
    remove_column :products, :has_sidebars
    remove_column :products, :has_table_of_contents
  end
end
