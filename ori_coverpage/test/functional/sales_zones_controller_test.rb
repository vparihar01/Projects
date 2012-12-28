require File.dirname(__FILE__) + '/../test_helper'

class SalesZonesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :sales_zones, :postal_codes
  
  def setup
    @controller = SalesZonesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end

  test "should_create_valid_sales_zone" do
    assert_difference SalesZone, :count do
      post :create, :sales_zone => { :name => 'AL', :postal_code_list => '36608' }
    end
    assert_redirected_to sales_zones_url
    assert_equal "The sales zone has been created.", flash[:notice]
  end
  
  test "should_update_valid_sales_zone" do
    @sales_zone = SalesZone.first
    put :update, :id => @sales_zone.id, 
      :sales_zone => @sales_zone.attributes.merge('name' => 'Foo')
    assert_redirected_to sales_zone_url(@sales_zone)
    assert_equal "The sales zone has been updated.", flash[:notice]
    assert_equal 'Foo', @sales_zone.reload.name
  end
end
