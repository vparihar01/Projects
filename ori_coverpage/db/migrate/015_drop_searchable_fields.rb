class DropSearchableFields < ActiveRecord::Migration
  def self.up
    [:customers, :users, :sales_teams].each do |t|
      remove_column t, :searchable
    end
  end

  def self.down
    [:customers, :users, :sales_teams].each do |t|
      add_column t, :searchable, :text
    end
  end
end
