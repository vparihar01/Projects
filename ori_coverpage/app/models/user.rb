require 'digest/sha1'
class User < ActiveRecord::Base
  has_one :managed_team, :class_name => 'SalesTeam', :foreign_key => 'managed_by'
  belongs_to :sales_team
  has_many :addresses, :as => :addressable
  has_one :cart
  has_many :quotes
	has_many :specs, :as => :specable
  has_many :orders, :class_name => 'Sale'
  has_one :wishlist
  has_and_belongs_to_many :products, :uniq => true
  has_and_belongs_to_many :downloads, :class_name => 'ProductDownload', :uniq => true
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates :name, :presence => true
  validates :email, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i}, :uniqueness => {:case_sensitive => false}
  validates :password, :length => {:within => 4..40}, :confirmation => true, :if => :password_required?
  before_save :encrypt_password
  
  # preferences (using 'preference' engine)
  preference :email_sale_status, :default => true

  # Authenticates a user by their email address and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find_by_email(email) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end
  
  def to_s
    name
  end
  
  def admin?
    self.is_a?(Admin)
  end
  
  def head_sales_rep?
    self.managed_team ? true : false
  end

  def customer?
    self.is_a?(Customer)
  end
  
  def self.to_dropdown
    order('name ASC').all.collect {|t| [t.name, t.id]}
  end

  def primary_address
    self.addresses.where('is_primary = 1').first
  end
  
  # returns a string with a decorated email address
  # eg. "Quentin <quentin@example.com>"
  def email_with_name
    "#{self.name} <#{self.email}>"
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end 
    
end
