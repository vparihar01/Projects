class CreateSeries < ActiveRecord::Migration
  def self.up
    require 'importer'
    
    create_table :categories do |t|
      t.column :name, :string
    end
    
    add_column :products, :category_id, :integer
    add_column :products, :series_id, :integer
    add_column :products, :sub_series_id, :integer
    add_column :products, :description, :text
    add_column :products, :available_on, :date
    add_column :products, :reading_level, :string
    add_column :products, :type, :string
    
    add_index :products, :reading_level
    
    #Importer.import_products_and_set(true)
  end

  def self.down
    drop_table :series
    drop_table :categories
    remove_column :products, :category_id
    remove_column :products, :series_id
    remove_column :products, :sub_series_id
    remove_column :products, :description
    remove_column :products, :available_on
    remove_column :products, :reading_level
    remove_column :products, :type
  end
end
