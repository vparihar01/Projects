require File.dirname(__FILE__) + '/../test_helper'
require 'editorial_reviews_controller'

# Re-raise errors caught by the controller.
class EditorialReviewsController; def rescue_action(e) raise e end; end

class EditorialReviewsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :editorial_reviews, :editorial_reviews_products

  def setup
    @controller = EditorialReviewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login, anonymous by default
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:editorial_reviews)
  end

  test "should_show_editorial_review" do
    editorial_review = editorial_reviews(:one)
    get :show, :id => editorial_review.id
    assert_response :success
  end

  test "should_test_search" do
    product = products(:old)
    get :search, :isbn => product.isbn
    assert_response :success
    assert_not_nil assigns(:product)
    assert_not_nil assigns(:editorial_reviews)
    assert_template 'index'
  end

end
