class CreateAssemblyAssignments < ActiveRecord::Migration
  def self.up
    create_table :assembly_assignments do |t|
      t.column :assembly_id, :integer
      t.column :product_id, :integer
      t.timestamps
    end
    Title.all.each do |t|
      execute("INSERT INTO assembly_assignments (assembly_id, product_id, created_at, updated_at) VALUES (#{t.assembly_id}, #{t.id}, NOW(), NOW())") unless t.assembly_id.blank?
      execute("INSERT INTO assembly_assignments (assembly_id, product_id, created_at, updated_at) VALUES (#{t.sub_assembly_id}, #{t.id}, NOW(), NOW())") unless t.sub_assembly_id.blank?
    end
    execute("UPDATE products SET type='Assembly' WHERE type='SubAssembly'")
    # Remove product fields assembly_id, sub_assembly_id in a subsequent migration
  end

  def self.down
    drop_table :assembly_assignments
  end
end
