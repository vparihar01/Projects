class CardAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :card_authorizations do |t|
      t.column :user_id, :integer
      t.column :cart_id, :integer
      t.column :transaction_id, :string, :limit => 20
      t.column :first_name, :string, :limit => 30
      t.column :last_name, :string, :limit => 30
      t.column :number, :string, :limit => 20
      t.column :month, :integer
      t.column :year, :integer
      t.column :card_type, :string, :limit => 20
      t.column :address1, :string, :limit => 80
      t.column :city, :string, :limit => 40
      t.column :state, :string, :limit => 20
      t.column :zip, :string, :limit => 20
      t.column :country, :string, :limit => 20
      t.column :amount, :decimal, :precision => 6, :scale => 2, :default => 0
    end
  end

  def self.down
    drop_table :card_authorizations
  end
end
