require File.dirname(__FILE__) + '/../../test_helper'

class CouponsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :discounts, :users

  def setup
    @controller = Admin::CouponsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_be_viewable_to_admins" do
    login_as :admin
    get :index
    assert_template 'index'
    assert_not_nil assigns(:coupons)
    assert_equal assigns(:coupons).size, Coupon.count
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

  test "should_create_valid_coupon" do
    assert_difference Discount, :count do
      post :create, :coupon => valid_coupon
      assert_not_nil assigns(:coupon)
      assert_redirected_to admin_coupons_url
      assert_equal 'Coupon was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_invalid_coupon" do
    post :create, :coupon => {:name => 'Invalid coupon'}
    assert_not_nil assigns(:coupon)
    assert_response :success
    assert_template 'new'
    assert assigns(:coupon).errors.collect { |field,error| "#{field} #{error}" }.include?("code can't be blank")
  end

end
