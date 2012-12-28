class AddMoreTcwColumnsToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :proprietary_id, :string, :limit => 16
    add_column :products, :catalog_page, :integer, :limit => 4
    add_column :products, :has_author_biography, :boolean, :default => false, :null => false
    add_column :products, :has_map, :boolean, :default => false, :null => false
    add_column :products, :has_timeline, :boolean, :default => false, :null => false
    change_column :products, :has_index, :boolean, :default => false, :null => false
    change_column :products, :has_bibliography, :boolean, :default => false, :null => false
    change_column :products, :has_glossary, :boolean, :default => false, :null => false
    change_column :products, :has_sidebars, :boolean, :default => false, :null => false
    change_column :products, :has_table_of_contents, :boolean, :default => false, :null => false
    rename_column :products, :has_sidebars, :has_sidebar
  end

  def self.down
    remove_column :products, :proprietary_id
    remove_column :products, :catalog_page
    remove_column :products, :has_author_biography
    remove_column :products, :has_map
    remove_column :products, :has_timeline
    rename_column :products, :has_sidebar, :has_sidebars
    change_column :products, :has_index, :boolean, :default => nil, :null => true
    change_column :products, :has_bibliography, :boolean, :default => nil, :null => true
    change_column :products, :has_glossary, :boolean, :default => nil, :null => true
    change_column :products, :has_sidebars, :boolean, :default => nil, :null => true
    change_column :products, :has_table_of_contents, :boolean, :default => nil, :null => true
  end
end
