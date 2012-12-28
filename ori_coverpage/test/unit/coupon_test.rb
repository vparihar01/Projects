require File.dirname(__FILE__) + '/../test_helper'

class CouponTest < ActiveSupport::TestCase
  fixtures :discounts
  
  def setup
    # any initialization needed for the tests
  end

  test "should_check_validation" do
    @coupon = Coupon.new()
    assert !@coupon.save
    @coupon.code = 'TESTCOUPON'
    assert @coupon.save
  end
end
