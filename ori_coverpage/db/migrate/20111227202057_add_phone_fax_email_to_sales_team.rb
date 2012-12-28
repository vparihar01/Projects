class AddPhoneFaxEmailToSalesTeam < ActiveRecord::Migration
  def self.up
    add_column :sales_teams, :phone, :string
    add_column :sales_teams, :fax, :string
    add_column :sales_teams, :email, :string
  end

  def self.down
    remove_column :sales_teams, :email
    remove_column :sales_teams, :fax
    remove_column :sales_teams, :phone
  end
end
