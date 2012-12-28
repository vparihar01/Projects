class ChangeDefaultOnAlsQuizAmount < ActiveRecord::Migration
  def self.up
    change_column :line_item_collections, :alsquiz_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  end

  def self.down
    change_column :line_item_collections, :alsquiz_amount, :decimal, :precision => 11, :scale => 2, :default => nil
  end
end
