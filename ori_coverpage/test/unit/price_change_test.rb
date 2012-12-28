require 'test_helper'

class PriceChangeTest < ActiveSupport::TestCase

  test "should prepare all price changes" do
    assert_not_equal 0, PriceChange.undistributed.count
    PriceChange.distribute
    assert_equal 0, PriceChange.undistributed.count
  end

  test "should calculate assembly price" do
    CONFIG[:calculate_assembly_price] = true
    price_change = price_changes :title_in_assembly
    new_price = price_change.price
    old_price = price_change.product_format.price
    assembly = price_change.product_format.product.assemblies.first
    price_change.update_attributes(:implement_on => Date.today)
    assert_difference 'assembly.reload.default_format.price', new_price - old_price do
      price_change.distribute!
      price_change.implement!
    end
  end

  test "should not calculate assembly price" do
    CONFIG[:calculate_assembly_price] = false
    price_change = price_changes :title_in_assembly
    new_price = price_change.price
    old_price = price_change.product_format.price
    assembly = price_change.product_format.product.assemblies.first
    price_change.update_attributes(:implement_on => Date.today)
    assert_no_difference 'assembly.reload.default_format.price' do
      price_change.distribute!
      price_change.implement!
    end
  end

  test "should calculate list price" do
    CONFIG[:calculate_list_price] = true
    price_change = price_changes :title_in_assembly
    product_format = price_change.product_format
    new_price = (price_change.price / CONFIG[:member_price_decimal]).round(2)
    old_price = price_change.product_format.price_list
    price_change.update_attributes(:implement_on => Date.today)
    price_change.distribute!
    price_change.implement!
    assert_equal new_price, product_format.reload.price_list
    assert_not_equal old_price, product_format.reload.price_list
  end

end
