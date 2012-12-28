class RemoveProductsInterestLevelColumn < ActiveRecord::Migration
  def self.up
    remove_column :products, :interest_level
  end

  def self.down            
    add_column :products, :interest_level, :string, :limit => 32    
    
    Product.reset_column_information
    Product.all.each do |p|
  		p.interest_level = "Grades #{p.level_min}-#{p.level_max}"
  		p.save
    end
  end
end 
