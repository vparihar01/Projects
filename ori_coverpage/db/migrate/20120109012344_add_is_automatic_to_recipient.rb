class AddIsAutomaticToRecipient < ActiveRecord::Migration
  def self.up
    add_column :recipients, :is_automatic, :boolean, :default => false, :null => false
    Recipient.reset_column_information
    Recipient.where("name != 'mba' AND name != 'cg' AND name NOT LIKE 'test%'").each do |recipient|
      recipient.toggle!(:is_automatic)
    end
  end

  def self.down
    remove_column :recipients, :is_automatic
  end
end
