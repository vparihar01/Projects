class Contact < ActiveRecord::Base
  acts_without_database :name => :string, :email => :string, :comments => :string, :subscribe => :integer

  validates :name, :presence => true
  validates :email, :presence => true
  validates :comments, :presence => true
  validates :email, :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :on => :create }, :allow_blank => true
end
