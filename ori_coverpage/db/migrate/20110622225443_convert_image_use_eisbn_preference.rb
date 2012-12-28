class ConvertImageUseEisbnPreference < ActiveRecord::Migration
  def self.up
    execute "UPDATE `preferences` SET `name` = 'image_naming', `value` = 'pdf' WHERE `name` = 'image_use_eisbn' AND `value` = '1'"
    execute "UPDATE `preferences` SET `name` = 'image_naming', `value` = 'default' WHERE `name` = 'image_use_eisbn' AND `value` != '1'"
  end

  def self.down
    execute "UPDATE `preferences` SET `name` = 'image_use_eisbn', `value` = '1' WHERE `name` = 'image_naming' AND `value` = 'pdf'"
    execute "UPDATE `preferences` SET `name` = 'image_use_eisbn', `value` = '0' WHERE `name` = 'image_naming' AND `value` != 'pdf'"
  end
end
