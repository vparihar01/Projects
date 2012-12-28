class CreateEdgateStandards < ActiveRecord::Migration
  def self.up
    create_table :edgate_standards do |t|
      t.string :zone_code, :limit => 32
      t.string :grade, :limit =>2
      t.string :subject
      t.integer :standard_id_parent
      t.integer :standard_id
      t.integer :level, :limit => 1
      t.integer :sequence, :limit => 8
      t.string :label, :limit => 32
      t.text :description

      t.timestamps
    end

      add_index :edgate_standards, :standard_id, :name => "standard_id"
      add_index :edgate_standards, :standard_id_parent, :name => "standard_id_parent"
      add_index :edgate_standards, :zone_code, :name => "zone_code"
      add_index :edgate_standards, :subject, :name => "subject"
      add_index :edgate_standards, :grade, :name => "grade"
  end

  def self.down
    drop_table :edgate_standards
  end
end
