class CreateEdgateCrossrefs < ActiveRecord::Migration
  def self.up
    create_table :edgate_crossrefs, :options => 'ENGINE=InnoDB MAX_ROWS=3000000' do |t|
      t.integer :edgate_id
      t.integer :standard_id

      t.timestamps
    end

    add_index :edgate_crossrefs, :edgate_id, :name => "edgate_id"
    add_index :edgate_crossrefs, :standard_id, :name => "standard_id"
  end

  def self.down
    drop_table :edgate_crossrefs
  end
end
