class AddLevelMinMaxColumns < ActiveRecord::Migration
  def self.up    
    require 'importer'
    
    add_column :products, :level_min, :integer, :limit => 2   
    add_column :products, :level_max, :integer, :limit => 2   
    
    Product.reset_column_information
    Product.all.each do |p| 
      m = /.*(\d+)-(\d+)$/.match(p.interest_level)
  		p.level_min = m[1] 
  		p.level_max = m[2] 
  		p.save
    end  
    
  end

  def self.down
    remove_column :products, :level_min
    remove_column :products, :level_max
  end
end
