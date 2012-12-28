class CreateErrata < ActiveRecord::Migration
  def self.up
    create_table :errata do |t|
      t.integer :product_format_id, :nil => false
      t.string :edition, :size => 255, :nil => true   # future use
      t.string :erratum_type, :size => 64, :nil => false
      t.integer :user_id, :nil => true                # used when restricted to logged in users
      t.string :name, :size => 255, :nil => false     # used when not restricted to logged in users
      t.string :email, :size => 255, :nil => false    # used when not restricted to logged in users
      t.integer :page_number, :nil => false
      t.text :description, :nil => false
      t.string :status, :size=> 64, :nil => false, :default => 'Submitted'

      t.timestamps
    end
  end

  def self.down
    drop_table :errata
  end
end
