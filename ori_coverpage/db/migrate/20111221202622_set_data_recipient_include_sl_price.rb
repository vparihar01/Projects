class SetDataRecipientIncludeSlPrice < ActiveRecord::Migration
  def self.up
    DataRecipient.all.each do |recipient|
      if recipient.preferred_data_template == "onix"
        recipient.update_attribute(:preferred_data_include_sl_price, true)
      end
      if recipient.preferred_data_template == "onix_retail"
        recipient.update_attribute(:preferred_data_template, "onix")
      end
    end
  end

  def self.down
    DataRecipient.all.each do |recipient|
      if recipient.preferred_data_template == "onix" && recipient.preferred_data_include_sl_price == false
        recipient.update_attribute(:preferred_data_template, "onix_retail")
      end
    end
    execute "DELETE FROM preferences WHERE name='data_include_sl_price'";
  end
end
