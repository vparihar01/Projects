class RenameSeriesColumn < ActiveRecord::Migration
  def self.up
    rename_column :products, :series_id, :assembly_id
    rename_column :products, :sub_series_id, :sub_assembly_id
    execute("UPDATE products SET type = 'Assembly' WHERE type = 'Series'")
    execute("UPDATE products SET type = 'SubAssembly' WHERE type = 'SubSeries'")
  end

  def self.down
    rename_column :products, :assembly_id, :series_id
    rename_column :products, :sub_assembly_id, :sub_series_id
    execute("UPDATE products SET type = 'Series' WHERE type = 'Assembly'")
    execute("UPDATE products SET type = 'SubSeries' WHERE type = 'SubAssembly'")
  end
end
