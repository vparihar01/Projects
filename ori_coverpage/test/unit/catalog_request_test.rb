require File.dirname(__FILE__) + '/../test_helper'

class CatalogRequestTest < ActiveSupport::TestCase
  fixtures :catalog_requests, :addresses

  test "should_not_create_invalid_catalog_request" do
    assert_difference 'CatalogRequest.count', 0 do
      @catalog_request = CatalogRequest.new()
      assert !@catalog_request.save
      assert @catalog_request.errors.collect { |field,error| "#{field} #{error}" }.include?("base Address missing")
    end
  end

  test "should_create_valid_catalog_request_and_check_out_methods" do
    @address = Address.all.last

    assert_difference 'CatalogRequest.count' do
      @catalog_request = CatalogRequest.new(:address => @address)
      assert @catalog_request.save
    end
    
    # check that address was correctly set and 'shortcut' methods of catalog_request work
    assert_equal @address.zone_name, @catalog_request.zone_name
    assert_equal @address.postal_code_name, @catalog_request.postal_code_name
    assert_equal @address.country_name, @catalog_request.country_name
  end
end
