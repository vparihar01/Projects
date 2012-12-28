class RenameRecipientsIndex < ActiveRecord::Migration
  def self.up
    rename_index :recipients, 'index_recipients_on__name_and_type', 'index_recipients_on_name_and_type'
  end

  def self.down
    rename_index :recipients, 'index_recipients_on_name_and_type', 'index_recipients_on__name_and_type'
  end
end
