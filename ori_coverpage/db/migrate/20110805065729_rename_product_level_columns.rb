class RenameProductLevelColumns < ActiveRecord::Migration
  def self.up
    execute "UPDATE `products` SET level_min=(level_min+2) where level_min >= -1"
    execute "UPDATE `products` SET level_max=(level_max+2) where level_max >= -1"
    execute "UPDATE `products` SET reading_level=(reading_level+2) where reading_level >= 1"
    execute "UPDATE `products` SET reading_level=1 where reading_level = 'P'"
    execute "UPDATE `products` SET reading_level=2 where reading_level = 'K'"
    rename_column :products, :level_min, :interest_level_min_id
    rename_column :products, :level_max, :interest_level_max_id
    rename_column :products, :reading_level, :reading_level_id
  end

  def self.down
    rename_column :products, :interest_level_min_id, :level_min
    rename_column :products, :interest_level_max_id, :level_max
    rename_column :products, :reading_level_id, :reading_level
    execute "UPDATE `products` SET level_min=(level_min-2) where level_min >= 1"
    execute "UPDATE `products` SET level_max=(level_max-2) where level_max >= 1"
    execute "UPDATE `products` SET reading_level=(reading_level-2) where reading_level >= 3"
    execute "UPDATE `products` SET reading_level='P' where reading_level = 1"
    execute "UPDATE `products` SET reading_level='K' where reading_level = 2"
  end
end
