class CreatePostedTransactionLines < ActiveRecord::Migration
  def self.up
    require 'importer'
    
    create_table :posted_transaction_lines do |t|
      t.column :posted_transaction_id, :integer
      t.column :product_id, :integer
      t.column :quantity, :integer
      t.column :unit_amount_in_cents, :integer
      t.column :total_amount_in_cents, :integer
      t.column :rep_base_in_cents, :integer
    end
    
    #Importer.import_posted_transaction_lines('posted_tran_lines.mer', true)
    
    add_index :posted_transaction_lines, :product_id
    add_index :posted_transactions, :customer_id
  end

  def self.down
    drop_table :posted_transaction_lines
  end
end
