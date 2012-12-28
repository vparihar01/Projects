class SetDownloadCounterDefaultToZero < ActiveRecord::Migration
  def self.up
    change_column :teaching_guides, :download_counter, :integer, :default => 0, :null => false
    change_column :handouts, :download_counter, :integer, :default => 0, :null => false
  end

  def self.down
    change_column :teaching_guides, :download_counter, :integer, :default => nil, :null => true
    change_column :handouts, :download_counter, :integer, :default => nil, :null => true
  end
end
