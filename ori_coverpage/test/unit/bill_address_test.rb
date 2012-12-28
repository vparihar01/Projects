require File.dirname(__FILE__) + '/../test_helper'

class BillAddressTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :addresses, :postal_codes, :zones, :countries
  
  def setup
    # any initialization needed for the test cases
  end
  
  test "the truth" do
    assert true
  end
end