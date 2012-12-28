require File.dirname(__FILE__) + '/../test_helper'
require 'downloads_controller'

# Re-raise errors caught by the controller.
class DownloadsController; def rescue_action(e) raise e end; end

class DownloadsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :downloads, :tags, :taggings

  def setup
    @controller = DownloadsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login, anonymous testing
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.where("is_visible = ?", true).all, assigns(:downloads)
  end

  test "admin_should_get_index_with_all_downloads" do
    login_as :admin
    get :index
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.order(:title), assigns(:downloads)
  end


  test "should_get_visible_tagged_downloads_if_not_admin" do
    get :tag, :tag => 'one'
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.find_tagged_with("one", :conditions => "is_visible = TRUE"), assigns(:downloads)
  end

  test "should_get_all_tagged_downloads_if_admin" do
    login_as :admin
    get :tag, :tag => 'one'
    assert_response :success
    assert_not_nil assigns(:downloads)
    assert_equal Download.find_tagged_with("one"), assigns(:downloads)
  end

  test "attempt_to_click_invisible_file" do
    put :click, :id => downloads(:invisible).to_param
    assert_redirected_to downloads_url
    assert_equal "The file you requested is no longer available.", flash[:notice]
  end

  test "should_show_download" do
    get :show, :id => downloads(:two).id.to_param
    assert_response :success
    assert_not_nil assigns(:download)
  end

  test "attempt_to_show_invisible_download_should_not_be_completed_for_users" do
    get :show, :id => downloads(:invisible).id.to_param
    assert_redirected_to downloads_url
    assert_equal "The file you requested is no longer available.", flash[:notice]
  end

  test "attempt_to_show_invalid_download" do
    get :show, :id => Download.last.id + 1
    assert_redirected_to downloads_url
    assert_equal "Unknown ID", flash[:error]
  end


end
