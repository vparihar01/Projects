require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :addresses, :postal_codes, :zones, :countries
  
  def setup
    @user = users :admin
    @address = @user.addresses.first
  end
  
  test "should_be_made_primary_for_a_user_with_no_primary_address" do
    @user.addresses.update_all('is_primary = 0')
    @address.is_primary = false
    @address.save
    assert_equal true, @address.is_primary?
  end
  
  test "should_unset_another_primary_address_when_creating_a_new_primary_address" do
    assert_equal true, @address.is_primary?
    @new_address = @user.addresses.build(@address.attributes)
    #Address.should.differ(:count).by(1) do
    assert_difference Address, :count, 1 do
      @new_address.save
    end
    assert_equal true, @new_address.is_primary?
    assert_equal false, @address.reload.is_primary?
  end
end