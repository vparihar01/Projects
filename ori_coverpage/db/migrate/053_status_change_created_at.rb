class StatusChangeCreatedAt < ActiveRecord::Migration
  def self.up
    rename_column :status_changes, :changed_at, :created_at
  end

  def self.down
    rename_column :status_changes, :created_at, :changed_at
  end
end
