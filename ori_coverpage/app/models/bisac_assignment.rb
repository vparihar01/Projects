class BisacAssignment < ActiveRecord::Base
  belongs_to :bisac_subject
  belongs_to :product

  validates :product_id, :presence => true
  validates :bisac_subject_id, :inclusion => { :in => BisacSubject.all.map(&:id) }
end
