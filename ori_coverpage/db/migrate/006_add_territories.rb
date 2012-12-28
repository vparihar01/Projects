class AddTerritories < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.column :name, :string
      t.column :iso_code_2, :string
      t.column :iso_code_3, :string
      t.column :fedex_code, :string
      t.column :ufsi_code, :string
    end
    
    create_table :zones do |t|
      t.column :name, :string
      t.column :code, :string
      t.column :country_id, :integer
    end
    
    create_table :postal_codes do |t|
      t.column :name, :string
      t.column :zone_id, :integer
    end
    
    add_index :postal_codes, :name, :unique => true
    add_index :postal_codes, :zone_id
  end

  def self.down
    drop_table :countries
    drop_table :zones
    drop_table :postal_codes
  end
end
