class CreateEdgateObjects < ActiveRecord::Migration
  def self.up
    create_table :edgate_objects, :force => true do |t|
      t.integer :edgate_id
      t.string :products_id, :limit => 32
      t.string :objects_name

      t.timestamps
    end

    add_index :edgate_objects, :edgate_id, :name => "edgate_id"
    add_index :edgate_objects, :products_id, :name => "isbn"
  end

  def self.down
    drop_table :edgate_objects
  end
end
