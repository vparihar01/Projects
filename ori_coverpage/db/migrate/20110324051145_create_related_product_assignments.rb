class CreateRelatedProductAssignments < ActiveRecord::Migration
  def self.up
    create_table :related_product_assignments do |t|
      t.column :product_id, :integer
      t.column :related_product_id, :integer
      t.column :relation, :string, :limit => 64
    end
    add_index :related_product_assignments, ["product_id"], :name => "index_rpa_on_product_id"
    add_index :related_product_assignments, ["product_id", "relation"], :name => "index_rpa_on_product_id_and_relation"
  end

  def self.down
    drop_table :related_product_assignments
  end
end
