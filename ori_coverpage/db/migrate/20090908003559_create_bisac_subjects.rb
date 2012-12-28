class CreateBisacSubjects < ActiveRecord::Migration
  def self.up
    create_table :bisac_subjects do |t|
      t.column :code, :string
      t.column :literal, :string
      t.column :seq, :integer
      t.column :trans, :string
      t.column :comments, :text
    end
  end

  def self.down
    drop_table :bisac_subjects
  end
end
