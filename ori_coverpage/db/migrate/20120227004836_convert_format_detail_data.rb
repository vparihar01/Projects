class ConvertFormatDetailData < ActiveRecord::Migration
  def self.up
    execute "UPDATE `formats` SET `detail` = 'FlippingBook' WHERE `detail` = 'Adobe Flash'"
  end

  def self.down
    execute "UPDATE `formats` SET `detail` = 'Adobe Flash' WHERE `detail` = 'FlippingBook'"
  end
end
