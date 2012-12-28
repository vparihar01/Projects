require File.dirname(__FILE__) + '/../test_helper'
require 'products_controller'

# Re-raise errors caught by the controller.
class ProductsController; def rescue_action(e) raise e end; end

class ProductsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :contributors, :headlines

  def setup
    @controller = ProductsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # TODO: inspect the redirection behaviour in the code, as the redirects to shop work only if the user is logged in
  # Eg. /products -> redirects to /login if anonymous (should redirect to /shop)
  #     while /shop displays without requiring to log in
  # this is ambigous behaviour, but current tests consider that the software should work as-is
  # therefore each test case logs in as a regular user in order to avoid failures due to redirection to login

  test "index_should_redirect_to_shop" do
    login_as :quentin
    get :index
    assert_redirected_to shop_url
  end

  test "show_should_redirect_to_shop_show" do
    login_as :quentin
    get :show, :id => products(:recent).id
    assert_redirected_to show_url(:id => products(:recent).id)
  end

  test "should_get_tooltip" do
    get :tooltip, :id => products(:recent).to_param
    assert_redirected_to show_path(products(:recent))
  end

  test "should_get_tooltipx" do
    get :tooltipx, :id => products(:recent).to_param
    assert_redirected_to show_path(products(:recent))
  end

end
