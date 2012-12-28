require 'fastercsv'
class CreateContracts < ActiveRecord::Migration
  def self.up
    create_table :contracts do |t|
      t.column :start_on, :date
      t.column :end_on, :date
      t.column :rate, :float
      t.column :sales_team_id, :integer
      t.column :sales_zone_id, :integer
      t.column :category, :string, :default => 'All'
    end
    
    execute("insert into contracts (start_on, end_on, rate, sales_team_id, sales_zone_id, category) select start_on, end_on, rate, st.id, sz.id, if(sz.contact_type is null, 'All', sz.contact_type) from sales_teams st inner join sales_zones sz on st.id = sz.sales_team_id")
    
    add_column :posted_transactions, :contract_id, :integer
    add_column :postal_codes, :sales_zone_id, :integer
    add_index :postal_codes, :sales_zone_id
    
    Zone.all.each {|z| 
      if sz = SalesZone.where("name like '%#{z.name}%'").first
        PostalCode.update_all("sales_zone_id = #{sz.id}", "zone_id = #{z.id}")
      end 
    }
    
    remove_column :sales_teams, :start_on
    remove_column :sales_teams, :end_on
    remove_column :sales_teams, :rate
    remove_column :sales_zones, :contact_type
    remove_column :sales_zones, :sales_team_id
        
  end

  def self.down
    drop_table :contracts
    drop_table :postal_codes_sales_zones

    remove_column :posted_transactions, :contract_id
    
    remove_column :postal_codes, :sales_zone_id

    add_column :sales_teams, :start_on,    :date
    add_column :sales_teams, :end_on,      :date
    add_column :sales_teams, :rate,        :float
    add_column :sales_zones, :contact_type,  :string
    add_column :sales_zones, :sales_team_id, :integer
  end
end
