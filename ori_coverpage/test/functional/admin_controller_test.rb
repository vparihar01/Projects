require File.dirname(__FILE__) + '/../test_helper'

class AdminControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test "should_get_show" do
    @user = login_as :admin
    get :show
    assert_response :success
  end

  test "should_not_get_show" do
    get :show
    assert_response :not_found
  end
end
