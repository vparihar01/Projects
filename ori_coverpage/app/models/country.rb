class Country < ActiveRecord::Base
  has_many :zones
  
  def self.to_dropdown
    order("name").all.collect {|x| [x.name, x.id]}
  end
  
  def to_s
    self.name
  end
end