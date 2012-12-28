require File.dirname(__FILE__) + '/../test_helper'
require 'categories_controller'

# Re-raise errors caught by the controller.
class CategoriesController; def rescue_action(e) raise e end; end

class CategoriesControllerTest < ActionController::TestCase
  fixtures :categories, :products, :categories_products

  def setup
    @controller = CategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # these tests should run anonymously
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  test "should_show_products_from_first_category" do
    get :show, :id => categories(:one).to_param
    assert_response :success
    assert_not_nil assigns(:products)
  end
  
end
