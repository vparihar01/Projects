class CreatePostedTransactions < ActiveRecord::Migration
  def self.up
    create_table :posted_transactions do |t|
      t.column :purchase_order, :string
      t.column :posted_on, :date
      t.column :shipped_on, :date
      t.column :transacted_on, :date
      t.column :amount_in_cents, :integer
      t.column :ship_amount_in_cents, :integer
      t.column :ship_sale_amount_in_cents, :integer
      t.column :transaction_amount_in_cents, :integer
      t.column :tax_in_cents, :integer
      t.column :rep_base_in_cents, :integer
      t.column :sales_team_id, :integer
      t.column :sold_to, :integer
      t.column :type, :string
    end
  end

  def self.down
    drop_table :posted_transactions
  end
end
