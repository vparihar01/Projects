require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < ActiveSupport::TestCase
  fixtures :users, :contracts, :addresses, :postal_codes, :sales_zones, :sales_teams, :products, :line_item_collections, :line_items

  def setup
    @customer = users(:another_customer)
  end

  test "find_contract" do
    @contract = @customer.find_contract
    assert_equal contracts(:don_texas), @contract
  end

  test "purchased_products" do
    assert @customer.purchased_products.length == 2 # see line_item_collections.yml
  end

  # TODO Add more tests if want to test specific things (CC reaches 100% indirectly /by functional tests/)
end

