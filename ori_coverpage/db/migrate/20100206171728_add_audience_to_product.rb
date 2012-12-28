class AddAudienceToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :audience, :string, :default => 'Primary school', :null => false
  end

  def self.down
    remove_column :products, :audience
  end
end
