class Email < ActiveRecord::Base
  acts_without_database :email => :string, :message => :string, :cc => :integer

  validates :email, :presence => true, :allow_blank => true,
              :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :on => :create }
end
