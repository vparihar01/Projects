class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.column :user_id, :integer
      t.column :name, :string
      t.column :attention, :string
      t.column :street, :string
      t.column :suite, :string
      t.column :city, :string
      t.column :postal_code_id, :integer
    end
  end

  def self.down
    drop_table :addresses
  end
end
