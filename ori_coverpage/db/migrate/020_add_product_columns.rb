class AddProductColumns < ActiveRecord::Migration
  def self.up
    add_column :products, :copyright, :integer, :limit => 4
    add_column :products, :interest_level, :string, :limit => 32
    add_column :products, :graphics, :string, :limit => 64
    add_column :products, :pages, :integer, :limit => 4
    add_column :products, :binding, :string, :limit => 32
    add_column :products, :size, :string, :limit => 32
    add_column :products, :dewey, :string, :limit => 32
    add_column :products, :textbyline, :string
    add_column :products, :textspotlight, :string
    add_column :products, :alsdiskid, :string, :limit => 8
    add_column :products, :alspoints, :decimal, :precision => 3, :scale => 1
    add_column :products, :alsreadlevel, :decimal, :precision => 3, :scale => 1
    add_column :products, :srcdiskid, :string, :limit => 8
    add_column :products, :srcpoints, :decimal, :precision => 3, :scale => 1
    add_column :products, :srcreadlevel, :decimal, :precision => 3, :scale => 1
    add_column :products, :srclexile, :integer, :limit => 4
  end

  def self.down
    remove_column :products, :copyright
    remove_column :products, :interest_level
    remove_column :products, :graphics
    remove_column :products, :pages
    remove_column :products, :binding
    remove_column :products, :size
    remove_column :products, :dewey
    remove_column :products, :textbyline
    remove_column :products, :textspotlight
    remove_column :products, :alsdiskid
    remove_column :products, :alspoints
    remove_column :products, :alsreadlevel
    remove_column :products, :srcdiskid
    remove_column :products, :srcpoints
    remove_column :products, :srcreadlevel
    remove_column :products, :srclexile
  end
end
