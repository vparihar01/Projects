class CreateHandouts < ActiveRecord::Migration
  def self.up
    create_table :handouts do |t|
      t.string :name
      t.text :description
      t.integer :teaching_guide_id
      t.string :document
      t.integer :download_counter
      t.timestamps
    end
    add_index :handouts, ["teaching_guide_id"]
  end

  def self.down
    drop_table :handouts
  end
end
