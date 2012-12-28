class CreateBisacAssignments < ActiveRecord::Migration
  def self.up
    create_table :bisac_assignments do |t|
      t.integer :title_id
      t.integer :bisac_subject_id
      t.timestamps
    end
  end

  def self.down
    drop_table :bisac_assignments
  end
end
