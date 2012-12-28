class HostedEbooksTrial < ActiveRecord::Base
  acts_without_database :name => :string, :title => :string, :email => :string, :phone => :string, :organization => :string, :street => :string, :suite => :string, :city => :string, :country_id => :string, :postal_code => :string, :zone_id => :string, :rep => :string, :subscribe => :integer

  validates :name, :presence => true
  validates :email, :presence => true
  validates :email, :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :on => :create }, :allow_blank => true
  validates :organization, :presence => true
  validates :street, :presence => true
  validates :city, :presence => true
  validates :country_id, :presence => true
  validates :postal_code, :presence => true
  validates :zone_id, :presence => true
end
