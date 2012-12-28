class CreateStatusChanges < ActiveRecord::Migration
  def self.up
    create_table :status_changes do |t|
      t.column :line_item_collection_id, :integer
      t.column :status, :string
      t.column :changed_at, :datetime
    end
  end

  def self.down
    drop_table :status_changes
  end
end
