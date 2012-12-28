class BisacSubject < ActiveRecord::Base
  has_many :bisac_assignments
  has_many :products, :through => :bisac_assignments
end
