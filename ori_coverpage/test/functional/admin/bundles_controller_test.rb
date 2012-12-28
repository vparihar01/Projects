require File.dirname(__FILE__) + '/../../test_helper'
#require 'bundles_controller'

# Re-raise errors caught by the controller.
#class BundlesController; def rescue_action(e) raise e end; end

class BundlesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :discounts, :products, :users

  def setup
    @controller = Admin::BundlesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_be_viewable_to_admins" do
    login_as :admin
    get :index
    assert_template 'index'
    assert_not_nil assigns(:bundles)
    assert_equal assigns(:bundles).size, Bundle.count
  end


  test "should_not_be_viewable_to_users" do
    login_as :aaron
    get :index
    assert_response 404
  end

  test "should_test_if_new_page_forms_are_ok" do
    get :new
    assert_response :success
    assert_template 'new'

    post :create                  # should respond with the new form
    assert_response :success
    assert_template 'new'
  end

  test "should_create_valid_bundle" do
    assert_difference Discount, :count do
      post :create, :bundle => valid_bundle
      assert_not_nil assigns(:bundle)
      assert_redirected_to admin_bundles_url
      assert_equal valid_bundle['product_ids'], Discount.last.products.collect { |product| product.id }.compact
      assert_equal 'Bundle was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_invalid_bundle" do
    (invalid_bundle = valid_bundle)['product_ids'] = ''
    assert_difference Discount, :count, 0 do
      post :create, :bundle => invalid_bundle
      assert_not_nil assigns(:bundle)
      assert_response :success
      assert_template 'new'
      assert_not_equal 'Bundle was successfully created.', flash[:notice]
      assert assigns(:bundle).errors.collect { |field,error| "#{field} #{error}" }.include?("products can't be blank")
    end
  end


end
