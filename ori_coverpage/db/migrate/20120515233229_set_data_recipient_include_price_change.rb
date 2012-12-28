class SetDataRecipientIncludePriceChange < ActiveRecord::Migration
  def self.up
    DataRecipient.all.each do |recipient|
      if recipient.preferred_data_template == "onix"
        if recipient.name == 'bowker'
          recipient.update_attribute(:preferred_data_include_price_change, false)
        else
          recipient.update_attribute(:preferred_data_include_price_change, true)
        end
      end
    end
  end

  def self.down
    execute "DELETE FROM preferences WHERE name='data_include_price_change'";
  end
end
