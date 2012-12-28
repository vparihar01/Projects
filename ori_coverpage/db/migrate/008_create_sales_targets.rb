class CreateSalesTargets < ActiveRecord::Migration
  def self.up
    create_table :sales_targets do |t|
      t.column :sales_team_id, :integer
      t.column :year, :integer
      t.column :amount_in_cents, :integer
    end
  end

  def self.down
    drop_table :sales_targets
  end
end
