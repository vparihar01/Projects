class UpdatePostalCodeTaxRatePrecisionAndScale < ActiveRecord::Migration
  def self.up
    change_column :postal_codes, :tax_rate, :decimal, :precision => 6, :scale => 5
  end

  def self.down
    change_column :postal_codes, :tax_rate, :decimal, :precision => 6, :scale => 4
  end
end
