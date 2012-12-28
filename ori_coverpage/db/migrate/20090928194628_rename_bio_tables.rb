class RenameBioTables < ActiveRecord::Migration
  def self.up
    add_column :bios_products, :id, :primary_key
    rename_column :bios_products, :bio_id, :contributor_id
    remove_column :bios, :deleted_at
    rename_table :bios, :contributors
    rename_table :bios_products, :contributor_assignments
  end

  def self.down
    rename_table :contributors, :bios
    rename_table :contributor_assignments, :bios_products
    rename_column :bios_products, :contributor_id, :bio_id
    add_column :bios, :deleted_at, :datetime
    remove_column :bios_products, :id
  end
end
