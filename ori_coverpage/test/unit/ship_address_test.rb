require File.dirname(__FILE__) + '/../test_helper'

class ShipAddressTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :addresses, :postal_codes, :zones, :countries
  
  def setup
    # any initialization needed for the test cases
  end
  
  test "the truth" do
    # TODO Replace this with your real tests.
    assert true
  end
end