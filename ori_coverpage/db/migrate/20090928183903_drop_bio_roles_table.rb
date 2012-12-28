class DropBioRolesTable < ActiveRecord::Migration
  def self.up
    change_column :bios, :default_bio_role_id, :string, :limit => 64
    change_column :bios_products, :bio_role_id, :string, :limit => 64
    # original bio_roles data: id => role
    roles = {1 => "Author", 2 => "Illustrator", 3 => "Photographer", 4 => "Editor", 5 => "Content Adviser", 6 => "Author & Illustrator", 7 => "Designer"}
    # update data in bios, bios_products tables
    roles.each do |id, role|
      execute("UPDATE bios SET default_bio_role_id = '#{role}' WHERE default_bio_role_id = '#{id}'")
      execute("UPDATE bios_products SET bio_role_id = '#{role}' WHERE bio_role_id = '#{id}'")
    end
    rename_column :bios, :default_bio_role_id, :default_role
    rename_column :bios_products, :bio_role_id, :role
    drop_table :bio_roles
  end

  def self.down
    # original bio_roles data: id => role
    roles = {1 => "Author", 2 => "Illustrator", 3 => "Photographer", 4 => "Editor", 5 => "Content Adviser", 6 => "Author & Illustrator", 7 => "Designer"}
    # create bio_roles table
    create_table :bio_roles do |t|
      t.column "name", :string, :limit => 128, :default => "", :null => false
    end
    # update data in bio_roles, bios, bios_products tables
    roles.each do |id, role|
      execute("INSERT INTO bio_roles (id, name) VALUES ('#{id}', '#{role}')")
      execute("UPDATE bios SET default_role = '#{id}' WHERE default_role = '#{role}'")
      execute("UPDATE bios_products SET role = '#{id}' WHERE role = '#{role}'")
    end
    # change, rename columns
    change_column :bios, :default_role, :integer
    change_column :bios_products, :role, :integer
    rename_column :bios, :default_role, :default_bio_role_id
    rename_column :bios_products, :role, :bio_role_id
  end
end
