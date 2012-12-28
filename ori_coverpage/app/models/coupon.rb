class Coupon < Discount
  validates :code, :presence => true
end
