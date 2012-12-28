class AddProductSampleColumn < ActiveRecord::Migration
  def self.up
    add_column :products, :sample_id, :integer
  end

  def self.down
    remove_column :products, :sample_id
  end
end
