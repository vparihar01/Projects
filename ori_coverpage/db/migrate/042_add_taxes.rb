class AddTaxes < ActiveRecord::Migration
  def self.up
    add_column :products, :is_taxable, :boolean, :default => 1
    add_column :postal_codes, :tax_rate, :decimal, :precision => 4, :scale => 4, :default => 0
  end

  def self.down
    remove_column :products, :is_taxable
    remove_column :postal_codes, :tax_rate
  end
end
