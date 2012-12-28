class CreateTitleType < ActiveRecord::Migration
  def self.up
    execute("update products set type = 'Title' where type = 'Product'")
  end

  def self.down
    execute("update products set type = 'Product' where type = 'Title'")
  end
end
