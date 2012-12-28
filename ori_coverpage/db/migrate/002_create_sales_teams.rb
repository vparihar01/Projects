class CreateSalesTeams < ActiveRecord::Migration
  def self.up
    create_table :sales_teams do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :rate, :float
      t.column :category, :string
      t.column :start_on, :date
      t.column :end_on, :date
      t.column :managed_by, :integer
      t.column :searchable, :text
    end
  end

  def self.down
    drop_table :sales_teams
  end
end
