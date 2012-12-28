require File.dirname(__FILE__) + '/../test_helper'

class SalesZoneTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :sales_zones, :postal_codes, :contracts, :zones

  def setup
    @zone = SalesZone.find(1)
  end
  
  test "should_assign_postal_codes" do
    assert_difference SalesZone, :count do
      SalesZone.create(:name => 'AL', :postal_code_list => '36608')
    end
    @sales_zone = SalesZone.find(:last)
    assert_equal PostalCode.find_all_by_name('36608'), @sales_zone.postal_codes
  end
  
  test "should_list_postal_codes" do
    @zone = SalesZone.find(3)
    assert_equal('36608', @zone.postal_code_list)
    assert @zone.postal_codes << PostalCode.create(:name => '36609', :zone => Zone.find(1))
    assert_equal('36608, 36609', @zone.postal_code_list)
  end
  
  test "should_find_contract_for_category" do
    @contract = Contract.find(1)
    assert_equal(@contract, @zone.contracts.for_category('School'))
    assert_equal(@contract, @zone.contracts.for_category('All'))
  end

  test "should_return_name_as_string" do
    @zone = SalesZone.find(3)
    assert_equal @zone.name, @zone.to_s
  end
end
