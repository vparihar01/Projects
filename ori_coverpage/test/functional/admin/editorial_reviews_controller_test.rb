require File.dirname(__FILE__) + '/../../test_helper'

class Admin::EditorialReviewsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :editorial_reviews #, :editorial_reviews_products

  def setup
    @controller = Admin::EditorialReviewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end
  
  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:editorial_reviews)
    assert_equal EditorialReview.all, assigns(:editorial_reviews)
  end

  test "should_search_editorial_reviews" do
    get :index, :search => { :source_like => 'milkfarmproductions'}
    assert_response :success
    assert_not_nil assigns(:editorial_reviews)
    assert_equal EditorialReview.where("source like '%milkfarmproductions%'").all, assigns(:editorial_reviews)
  end

  test "should_get_index_of_reviews_related_to_a_product" do
    @product = products(:old)
    get :index, :product_id => @product.id
    assert_response :success
    assert_not_nil assigns(:editorial_reviews)
    assert_equal @product.editorial_reviews, assigns(:editorial_reviews)
    assert_not_equal EditorialReview.all, assigns(:editorial_reviews)
  end

  test "should_edit_editorial_review" do
    editorial_review = editorial_reviews(:one)
    get :edit, :id => editorial_review.id
    assert_response :success
    assert_template 'edit'
  end

  test "should_update_editorial_review" do
    editorial_review = editorial_reviews(:one)
    post :update, :id => editorial_review.id, :editorial_review => { :body => editorial_review.body.concat(" UPDATED") }
    assert_redirected_to editorial_reviews_url
    assert_equal 'Editorial Review was successfully updated.', flash[:notice]
  end

  test "should_not_update_editorial_review_with_errors" do
    editorial_review = editorial_reviews(:one)
    post :update, :id => editorial_review.id, :editorial_review => { :source => "" }
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:editorial_review)
    assert assigns(:editorial_review).errors.collect { |field,error| "#{field} #{error}" }.include?("source can't be blank")
    assert_not_equal editorial_review.reload.source, assigns(:editorial_review).source
    assert_not_equal 'Editorial Review was successfully updated.', flash[:notice]
  end

  test "should_check_new_editorial_review_form" do
    get :new
    assert_response :success
    assert_not_nil assigns(:editorial_review)
    assert_template 'new'
  end

  test "should_create_new_editorial_review" do
    assert_difference EditorialReview, :count do
      post :create, :editorial_review => valid_editorial_review
      assert_not_nil assigns(:editorial_review)
      assert_redirected_to editorial_reviews_url
      assert_equal 'Editorial Review was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_new_editorial_review_with_errors" do
    assert_difference EditorialReview, :count, 0 do
      post :create, :editorial_review => { :source => "", :body => 'erroneous review -- without source' }
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:editorial_review)
      assert assigns(:editorial_review).errors.collect { |field,error| "#{field} #{error}" }.include?("source can't be blank")
      assert_not_equal 'Editorial Review was successfully created.', flash[:notice]
    end
  end

  test "should_destroy_editorial_review" do
    assert_difference EditorialReview, :count, -1 do
      delete :destroy, :id => editorial_reviews(:one)
      assert_redirected_to admin_editorial_reviews_url
      assert_equal 'Editorial Review was deleted.', flash[:notice]
    end
  end

end
