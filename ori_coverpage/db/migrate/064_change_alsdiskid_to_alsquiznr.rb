class ChangeAlsdiskidToAlsquiznr < ActiveRecord::Migration
  def self.up
    rename_column :products, :alsdiskid, :alsquiznr
  end

  def self.down
    rename_column :products, :alsquiznr, :alsdiskid
  end
end
