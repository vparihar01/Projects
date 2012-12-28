require File.dirname(__FILE__) + '/../test_helper'
#require 'catalog_requests_controller'

# Re-raise errors caught by the controller.
#class CatalogRequestsController; def rescue_action(e) raise e end; end

class CatalogRequestsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :catalog_requests, :users, :addresses, :products

  def setup
    @controller = CatalogRequestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login, tests run as anonymous by default
  end

  test "should_get_the_new_request_form" do
    get :new
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_not_nil assigns(:address)
    assert_not_nil assigns(:postal_code)
    assert_template 'new'
  end

  test "should_get_the_new_request_form_as_registered_user" do
    login_as :quentin
    get :new
    assert_response :success
    assert_not_nil assigns(:catalog_request)
    assert_not_nil assigns(:address)
    #assert_not_nil assigns(:postal_code) # this is not assigned in the original code for registered users
    assert_template 'new'
    assert_equal assigns(:address), users(:quentin).primary_address
  end


  test "should_create_new_catalog_request" do
    assert_difference CatalogRequest, :count do
      post :create, valid_catalog_request
      assert_not_nil assigns(:catalog_request)
      assert_not_nil assigns(:address)
      assert_not_nil assigns(:postal_code)
      assert_redirected_to public_page_path(:help)
      assert_equal 'Catalog request was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_invalid_catalog_request" do
    assert_difference CatalogRequest, :count, 0 do
      invalid_catalog_request = valid_catalog_request
      invalid_catalog_request['catalog_request']['address_attributes']['name'] = "" # blank out name
      post :create, invalid_catalog_request

      assert_response :success
      assert_not_nil assigns(:catalog_request)
      assert_not_nil assigns(:address)
      assert_not_nil assigns(:postal_code)
      assert_template 'new'
      #assert_redirected_to public_page_path(:help)
      assert_not_equal 'Catalog request was successfully created.', flash[:notice]
      assert assigns(:address).errors.collect { |field,error| "#{field} #{error}" }.include?("name can't be blank")
    end
  end


  test "should_create_new_catalog_request_as_admin" do
    login_as :admin
    assert_difference CatalogRequest, :count do
      post :create, valid_catalog_request
      assert_not_nil assigns(:catalog_request)
      assert_not_nil assigns(:address)
      #assert_not_nil assigns(:postal_code)
      assert_redirected_to admin_catalog_requests_url
      assert_equal 'Catalog request was successfully created.', flash[:notice]
    end
  end

end
