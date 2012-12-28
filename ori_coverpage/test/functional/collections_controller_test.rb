require File.dirname(__FILE__) + '/../test_helper'

class CollectionsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :collections, :users, :products, :product_formats

  def setup
    @controller = CollectionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login by default
  end


  test "should_get_index" do
    @request.session[:user] = nil
    get :index
    assert_response :success
    assert_not_nil assigns(:collections)
  end

  test "should_show_collection" do
    @request.session[:user] = nil
    get :show, :id => collections(:two).to_param
    assert_response :success
    assert_not_nil assigns(:collection)
    assert_not_nil assigns(:titles)
    assert_not_nil assigns(:assemblies)
  end

  test "should_not_show_unreleased_collection" do
    get :show, :id => collections(:future_collection).to_param
    assert_redirected_to root_url
    assert_equal "Series not yet released.", flash[:error]
  end

  test "should_show_unreleased_collection_if_admin" do
    @user = login_as :admin
    get :show, :id => collections(:future_collection).to_param
    assert_response :success
    assert_select 'p', collections(:future_collection).description
  end
end
