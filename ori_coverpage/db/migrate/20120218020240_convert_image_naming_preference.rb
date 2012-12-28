class ConvertImageNamingPreference < ActiveRecord::Migration
  def self.up
    execute "UPDATE `preferences` SET `name` = 'image_format_id', `value` = '1' WHERE `name` = 'image_naming' AND `value` = 'default'"
    execute "UPDATE `preferences` SET `name` = 'image_format_id', `value` = '2' WHERE `name` = 'image_naming' AND `value` = 'pdf'"
    execute "UPDATE `preferences` SET `name` = 'image_format_id', `value` = '3' WHERE `name` = 'image_naming' AND `value` = 'trade'"
  end

  def self.down
    execute "UPDATE `preferences` SET `name` = 'image_naming', `value` = 'default' WHERE `name` = 'image_format_id' AND `value` = '1'"
    execute "UPDATE `preferences` SET `name` = 'image_naming', `value` = 'pdf' WHERE `name` = 'image_format_id' AND `value` = '2'"
    execute "UPDATE `preferences` SET `name` = 'image_naming', `value` = 'trade' WHERE `name` = 'image_format_id' AND `value` = '3'"
    # Delete 'image_format_id' preferences that don't conform to the aforementioned values
    execute "DELETE FROM `preferences` WHERE `name` = 'image_format_id'"
  end
end
