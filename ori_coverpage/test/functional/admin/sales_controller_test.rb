require File.dirname(__FILE__) + '/../../test_helper'

class Admin::SalesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :users, :card_authorizations
  
  def setup
    @controller = Admin::SalesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @sale = Sale.find(5)
    login_as :admin
  end
  
  test "should_be_viewable_to_admins" do
    login_as :admin
    get :index
    assert_template 'index'
    assert_not_nil assigns(:sales)
    assert_equal assigns(:sales).size, Sale.count
  end
  
  
  test "should_not_be_viewable_to_users" do
    login_as :aaron
    get :index
    assert_response 404
  end
    
  test "should_create_a_new_status_change_record_when_changed" do
    assert_difference StatusChange, :count, 1 do
      post :set_status, :id => @sale.id, :status => 'Shipped'
    end
  end
  
  test "should_catch_card_authorization_errors" do
    CardAuthorization.any_instance.expects(:capture).raises(StandardError, 'Bogus message')
    assert_difference StatusChange, :count, 0 do
      post :set_status, :id => @sale.id, :status => 'Paid'
    end
    assert_redirected_to admin_sale_url(@sale)
    assert_equal flash[:error], 'Bogus message'
  end
  
end
