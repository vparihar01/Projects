class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  belongs_to :postal_code 
  belongs_to :country
  
  validates :name, :presence => true
  validates :street, :presence => true
  validates :city, :presence => true
  validates :country_id, :presence => true
  
  validates :postal_code_id, :presence => true
  validates_associated :postal_code
  
  before_save :check_primary
  
  def to_html
    lines = [ :name, :attention, :street, :suite ].collect do |f|
      (value = self.send(f)).blank? ? nil : value
    end << "#{self.city}, #{self.postal_code}"
    lines.compact.map {|f| "<li>#{f}</li>"}.to_s
  end 
  
  def to_s
    lines = [ :name, :attention, :street, :suite ].collect do |f|
      (value = self.send(f)).blank? ? nil : (value + "\n")
    end << "#{self.city}, #{self.postal_code}"
    lines.compact.map {|f| "#{f}"}.to_s
  end
  
  def zone_name
    if self.postal_code.nil? || self.postal_code.zone.nil?
      ""
    else
      self.postal_code.zone.name
    end
  end 
  
  def postal_code_name
    if self.postal_code.nil?
      ""
    else
      self.postal_code.name
    end
  end
  
  def country_name
    if self.country.nil?
      ""
    else
      self.country.name
    end
  end
  
  protected
  
    # If saving a User address, make sure the user has one and only one
    # address flagged as primary
    def check_primary
      if self.addressable.is_a? User
        other_primary = self.addressable.addresses.count(:conditions => 'is_primary = 1' + (self.new_record? ? '' : " and id <> #{self.id}")) > 0
        if self.is_primary && other_primary
          self.addressable.addresses.update_all('is_primary = 0')
        elsif !self.is_primary && !other_primary
          self.is_primary = true
        end
      end
      true
    end
    
end
