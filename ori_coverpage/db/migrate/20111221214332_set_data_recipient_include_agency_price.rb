class SetDataRecipientIncludeAgencyPrice < ActiveRecord::Migration
  def self.up
    DataRecipient.where("name like ?", "%coresource%").all.each do |recipient|
      if recipient.preferred_data_template == "onix"
        recipient.update_attribute(:preferred_data_include_agency_price, true)
      end
    end
  end

  def self.down
    execute "DELETE FROM preferences WHERE name='data_include_agency_price'";
  end
end
