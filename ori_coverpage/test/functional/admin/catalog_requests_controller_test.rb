require File.dirname(__FILE__) + '/../../test_helper'

# Re-raise errors caught by the controller.
#class Admin::CatalogRequestsController; def rescue_action(e) raise e end; end

class Admin::CatalogRequestsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :catalog_requests, :addresses, :users, :products

  def setup
    @controller = Admin::CatalogRequestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:catalog_requests)
  end

  test "should_show_catalog_request" do
    get :show, :id => catalog_requests(:one)
    assert_response :success
    assert_not_nil assigns(:catalog_request)
  end

  test "should_not_show_invalid_catalog_request" do
    get :show, :id => CatalogRequest.last.id + 1
    assert_redirected_to admin_catalog_requests_url
    assert_nil assigns(:catalog_request)
    assert flash[:error].include?('Error finding catalog request')
  end

  test "should_destroy_catalog_request" do
    assert_difference CatalogRequest, :count, -1 do
      delete :destroy, :id => catalog_requests(:two).to_param
      assert_redirected_to admin_catalog_requests_url
    end
  end

  test "should_get_export" do
    get :export
    assert_response :success
    assert_not_nil assigns(:catalog_requests)
  end

  test "should_check_edit_catalog_request" do
    get :edit, :id => catalog_requests(:one)
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_template 'edit'
  end

  test "should_update_catalog_request" do
    get :edit, :id => catalog_requests(:one)
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_template 'edit'

    post :update, :id => assigns(:catalog_request).id,
      :catalog_request => { :is_processed => true },
      :address => valid_address                     # change the address
    assert_redirected_to admin_catalog_requests_url
    assert_equal 'Catalog request was successfully updated.', flash[:notice]
  end

  test "should_not_update_invalid_catalog_request" do
    get :edit, :id => catalog_requests(:one)
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_template 'edit'

    (invalid_address = valid_address)['name'] = ""
    post :update, :id => assigns(:catalog_request).id,
      :catalog_request => { :is_processed => true },
      :address => invalid_address                     # change the address, name is blank
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_not_equal 'Catalog request was successfully updated.', flash[:notice]
    assert assigns(:address).errors.collect { |field,error| "#{field} #{error}" }.include?("name can't be blank")
    assert_template 'edit'
  end
end
