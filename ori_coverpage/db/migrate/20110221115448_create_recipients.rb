class CreateRecipients < ActiveRecord::Migration
  def self.up
    create_table :recipients do |t|
      t.string :name, :length => 128, :nil => false
      t.string :type, :length => 128, :nil => false
      t.string :emails, :length => 4096, :nil => false
      t.string :ftp, :length => 256

      t.timestamps
    end

    add_index :recipients, [:name, :type], :unique => true, :name => 'index_recipients_on__name_and_type'
  end

  def self.down
    drop_table :recipients
  end
end
