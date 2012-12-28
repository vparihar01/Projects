class AddDateColumnsToAddresses < ActiveRecord::Migration
  def self.up
    add_timestamps(:addresses)
  end

  def self.down
    remove_timestamps(:addresses)
  end
end
