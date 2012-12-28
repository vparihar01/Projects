class CardAuthCaptures < ActiveRecord::Migration
  def self.up
    add_column :card_authorizations, :captured, :boolean
  end

  def self.down
    remove_column :card_authorizations, :captured
  end
end
