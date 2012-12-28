class DropEdgateTables < ActiveRecord::Migration
  def self.up
    drop_table :edgate_crossrefs
    drop_table :edgate_objects
    drop_table :edgate_levels
    drop_table :edgate_standards
  end

  def self.down
    # ActiveRecord::Migrator.migrate('db/migrate', 66)
    create_table :edgate_objects, :force => true do |t|
      t.integer :edgate_id
      t.string :products_id, :limit => 32
      t.string :objects_name
      t.timestamps
    end
    add_index :edgate_objects, :edgate_id, :name => "edgate_id"
    add_index :edgate_objects, :products_id, :name => "isbn"
    # ActiveRecord::Migrator.migrate('db/migrate', 67)
    create_table :edgate_levels do |t|
      t.string :zone_code
      t.integer :level
      t.text :description
      t.timestamps
    end
    add_index :edgate_levels, [:zone_code,:level], :name => "zone_code_level"
    # ActiveRecord::Migrator.migrate('db/migrate', 68)
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
    # ActiveRecord::Migrator.migrate('db/migrate', 69)
    create_table :edgate_crossrefs, :options => 'ENGINE=InnoDB MAX_ROWS=3000000' do |t|
      t.integer :edgate_id
      t.integer :standard_id
      t.timestamps
    end
    add_index :edgate_crossrefs, :edgate_id, :name => "edgate_id"
    add_index :edgate_crossrefs, :standard_id, :name => "standard_id"
  end
end
