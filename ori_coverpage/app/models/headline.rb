class Headline < ActiveRecord::Base
  validates :title, :presence => true, :allow_blank => false, :length => { :within => 3..255 }
  
end
