class Testimonial < ActiveRecord::Base
  validates :comment, :presence => true
  
end
