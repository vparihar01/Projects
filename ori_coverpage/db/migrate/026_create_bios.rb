class CreateBios < ActiveRecord::Migration
  def self.up
    create_table :bio_roles do |t|
      t.column "name", :string, :limit => 128, :default => "", :null => false
    end
    create_table :bios do |t|
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
      t.column "deleted_at", :datetime
      t.column "name", :string, :limit => 128, :default => "", :null => false
      t.column "description", :text, :default => "", :null => false
      t.column "default_bio_role_id", :integer
    end
    create_table :bios_products, :id => false do |t|
      t.column "bio_id", :integer, :default => 0, :null => false
      t.column "bio_role_id", :integer, :default => 0, :null => false
      t.column "product_id", :integer, :default => 0, :null => false
    end
    add_index :bios_products, ["bio_role_id"], :name => "fk_bp_bio_category"
    add_index :bios_products, ["product_id"], :name => "fk_bp_product"
  end

  def self.down
    drop_table :bio_roles
    drop_table :bios
    drop_table :bios_products
  end
end
