class RemoveProductSampleColumn < ActiveRecord::Migration
  def self.up
    remove_column :products, :sample_id
  end

  def self.down
    add_column :products, :sample_id, :integer
  end
end