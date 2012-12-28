class CreateEdgateLevels < ActiveRecord::Migration
  def self.up
    create_table :edgate_levels do |t|
      t.string :zone_code
      t.integer :level
      t.text :description

      t.timestamps
    end

    add_index :edgate_levels, [:zone_code,:level], :name => "zone_code_level"
  end

  def self.down
    drop_table :edgate_levels
  end
end
