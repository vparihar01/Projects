class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :title
      t.text :body
      t.string :path
      t.string :section, :limit => 32
      t.timestamps
    end
    add_index :pages, :path, :unique => true
    Page.create(:title => "About Us", :path => 'about')
    Page.create(:title => "Privacy Policy", :path => 'privacy')
    Page.create(:title => "Terms & Conditions", :path => 'terms')
    Page.create(:title => "Help", :path => 'help')
    Page.create(:title => "Discounts", :path => 'prices')
    Page.create(:title => "Shipping", :path => 'shipping')
    Page.create(:title => "Returns", :path => 'returns')
    Page.create(:title => "god", :path => 'god', :body => "DO NOT DELETE -- for internal monitoring purposes")
  end

  def self.down
    drop_table :pages
  end
end
