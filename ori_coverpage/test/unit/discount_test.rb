require File.dirname(__FILE__) + '/../test_helper'

class DiscountTest < ActiveSupport::TestCase
  fixtures :discounts, :products
  
  test "should_be_0_for_amounts_less_than_or_equal_to_zero" do
    @discount = Discount.new(:amount => 5)
    assert_equal @discount.calculate(0), 0
    assert_equal @discount.calculate(-1), 0
  end
  
  test "should_not_be_greater_than_the_subtotal" do
    @discount = Discount.new(:amount => 5)
    assert_equal @discount.calculate(4), 4
  end
  
  test "should_not_be_greater_than_the_amount" do
    @discount = Discount.new(:amount => 5)
    assert_equal @discount.calculate(5), 5
    assert_equal @discount.calculate(6), 5
  end
  
  test "should_calculate_based_on_percentage" do
    @discount = Discount.new(:amount => 0.1, :percent => true)
    assert_equal @discount.calculate(78.99).to_f, 7.9
  end
  
  test "should_not_be_available_if_starting_in_the_future" do
    assert !Discount.new(:start_on => 2.days.from_now.to_date).available?
  end
  
  test "should_not_be_available_if_ended_in_the_past" do
    assert !Discount.new(:end_on => 2.days.ago.to_date).available?
  end
  
  test "should_be_available_if_started_in_the_past" do
    assert Discount.new(:start_on => 1.week.ago.to_date).available?
  end
  
  test "should_be_available_if_ending_in_the_future" do
    assert Discount.new(:end_on => 1.week.from_now.to_date).available?
  end
  
  test "should_be_0_if_not_available" do
    @discount = Discount.new(:amount => 0.1, :percent => true, :end_on => 1.week.ago.to_date)
    assert_equal @discount.calculate(10), 0
  end
  
end

class DiscountBundleTest < ActiveSupport::TestCase
  fixtures :discounts, :products, :bundles_products
  
  def setup
    @bundle = Bundle.first
  end
  
#  test "should match the required set of products" do
#    @bundle.matches_products?([1,2]).should.be true
#  end
  
  test "should_not_match_when_missing_a_required_product" do
    assert !@bundle.matches_products?([1])
  end
  
  test "should_not_match_when_missing_a_required_product_regardless_of_other_products" do
    assert !@bundle.matches_products?([1,3])
  end
  
#  test "should_not_be_found_unless_it_matches_a_product_list" do
#    Bundle.for_products([1,2]).should.equal [@bundle]
#    Bundle.for_products([1,3]).should.equal []
#  end
  
  test "should_not_be_found_for_a_product_list_if_unavailable" do
    @bundle.update_attribute(:end_on, 1.day.ago)
    assert_equal Bundle.for_products([1,2]), []
  end
  
  test "should_match_for_any_code_when_bundle_code_is_nil_or_blank" do
    assert_nil @bundle.code
    assert @bundle.matches_code?('foo')
    @bundle.code = ''
    assert @bundle.matches_code?('foo')
  end
  
  test "should_match_for_a_matching_code" do
    @bundle.code = 'foo'
    assert @bundle.matches_code?('foo')
  end
  
  test "should_not_match_for_a_non_matching_code" do
    @bundle.code = 'foo'
    assert !@bundle.matches_code?('bar')
  end

  test "check_start_end_date_string_conversions" do
    @discount = discounts(:two_products)
    @discount.start_on = @discount.end_on = ""
    assert_nil @discount.start_on
    assert_nil @discount.end_on
    @discount.start_on = ( @discount.end_on = ( todays_date_string = Time.now.strftime("%m/%d/%Y") ) )
    assert_equal @discount.start_on.strftime("%m/%d/%Y"), todays_date_string
    assert_equal @discount.end_on.strftime("%m/%d/%Y"), todays_date_string
  end
  
  test "should_generate_dropdown_list_with_all_items" do
    @discount_drop_list = Discount.to_dropdown
    i = 0
    Discount.order('name').all.each do |discount|
      assert @discount_drop_list[i][0] = discount.name
      i += 1
    end
  end

#  test "should_not_be_found_for_qualifying_products_but_no_code_match" do
#    Bundle.for_products([1,2]).should.equal [@bundle]
#    @bundle.update_attribute(:code, 'foo')
#    Bundle.for_products([1,2]).should.not.equal [@bundle]
#  end
#
#  test "should_be_found_for_qualifying_products_and_code_match" do
#    @bundle.update_attribute(:code, 'foo')
#    Bundle.for_products([1,2], 'foo').should.equal [@bundle]
#  end
  
end