require File.dirname(__FILE__) + '/../test_helper'
require 'links_controller'

# Re-raise errors caught by the controller.
class LinksController; def rescue_action(e) raise e end; end

class LinksControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :links, :links_products, :products, :product_formats, :users

  def setup
    @controller = LinksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # do not login, most tests are for anonymous visitors
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:links)
  end

  test "should_show_first_link" do
    get :show, :id => links(:one).to_param
    assert_response :success
    assert_not_nil assigns(:link)
  end

  test "should_get_popular" do
    get :popular
    assert_response :success
    assert_not_nil assigns(:links)
  end

  test "should_get_recommended" do
    get :recommended
    assert_response :success
    assert_not_nil assigns(:kids)
    assert_not_nil assigns(:adults)
  end

  test "admin_link_views_should_not_be_counted_for_link_that_is_ok" do
    @link = links(:one)
    views = @link.views
    put :click, :id => @link.id
    assert_equal @link.views, views
    assert_redirected_to @link.url
  end

  test "user_link_views_should_be_counted_for_link_that_is_ok" do
    login_as :quentin
    @link = links(:one)
    views = @link.views
    put :click, :id => @link.id
    assert_equal @link.reload.views, views + 1
    assert_redirected_to @link.url
  end

  test "user_link_views_should_not_work_for_link_that_is_not_ok" do
    @link = links(:without_any_title)
    views = @link.views
    put :click, :id => @link.id
    assert_equal views, @link.reload.views
    assert_redirected_to links_url
    assert_equal "Invalid link", flash[:notice]
  end

  test "admin_link_views_should_work_for_link_that_is_not_ok" do
    login_as :admin
    @link = links(:without_any_title)
    views = @link.views
    put :click, :id => @link.id
    assert_equal views, @link.reload.views
    assert_redirected_to @link.url
  end

  test "should_search_by_isbn" do
    # get product id 1
    get :search, :q => "old"
    assert :success
    assert_not_nil assigns(:product)
    assert_not_nil assigns(:links)
  end
  
  test "should_search_by_name" do
    # get product id 1
    get :search, :q => "Old Book"
    assert :success
    assert_not_nil assigns(:product)
    assert_not_nil assigns(:links)
  end
  
  test "should_find_multiple_products" do
    # get product id 1 and 2
    get :search, :q => "Book"
    assert :success
    assert_not_nil assigns(:products)
    assert_blank assigns(:links)
    assert_nil assigns(:product)
  end
  
  test "should_perform_search_with_nonexisting_isbn" do
    get :search, :q => "this_should_generate_no_hits"
    assert :success
    assert_not_nil assigns(:links)
    assert_blank assigns(:links)
    assert_nil assigns(:product)
  end
  
  test "should_perform_search_as_admin" do
    login_as :admin
    get :search, :q => "old"
    assert :success
    assert_not_nil assigns(:links)
    assert_not_nil assigns(:product)
  end
  
  test "should_perform_search_with_nonexisting_isbn_as_admin" do
    login_as :admin
    get :search, :q => "this_should_generate_no_hits"
    assert :success
    assert_not_nil assigns(:links)
    assert_blank assigns(:links)
    assert_nil assigns(:product)
  end
  
end
