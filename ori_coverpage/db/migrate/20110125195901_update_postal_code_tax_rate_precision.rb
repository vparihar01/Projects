class UpdatePostalCodeTaxRatePrecision < ActiveRecord::Migration
  def self.up
    change_column :postal_codes, :tax_rate, :decimal, :precision => 6, :scale => 4
  end

  def self.down
    change_column :postal_codes, :tax_rate, :decimal, :precision => 5, :scale => 4
  end
end
