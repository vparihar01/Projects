require File.dirname(__FILE__) + '/../test_helper'

class PagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :pages, :users, :headlines, :editorial_reviews

  def setup
    @controller = PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # anonymous user by default
  end

  test "should_get_home_page" do
    get :home
    assert_response :success
  end

  test "should_get_a_404_on_invalid_page" do
    if CONFIG[:show_error_pages] == true
      get :view, :path => 'blablabla'
      assert_response :not_found
    else
      assert_raise(ApplicationController::PageNotFound) { get :view, :path => 'blablabla' }
    end
  end

  test "should_get_contact_form_for_visitors" do
    get :contact
    assert_response :success
    assert_not_nil assigns(:form)
    assert_nil assigns(:form).email
  end

  test "should_get_contact_form_for_registered_user" do
    @user = login_as :quentin
    get :contact
    assert_response :success
    assert_not_nil assigns(:form)
    assert_equal @user.email, assigns(:form).email
  end

  test "should_view_first_page" do
    get :view, :path => Page.find(1).path
    assert_response :success
  end

  test "should_view_about_page" do
    get :view, :path => pages(:about).path
    assert_response :success
  end

  test "should_not_show_admin_pages_to_visitors" do
    get :view, :path => pages(:admin).path
    assert_redirected_to root_path
  end

  test "should_show_admin_pages_to_admins" do
    @user = login_as :admin
    get :view, :path => pages(:admin).path
    assert_response :success
  end

  test "should_get_geolocation" do
    get :geolocation
    assert_response :success
  end

  test "should_get_subscribe" do
    # test disabled subscribe functionality
    CONFIG[:unsubscribe_url] = nil
    get :subscribe
    assert_redirected_to root_path
    assert_equal 'Newsletter subscribe functionality is not enabled.', flash[:error]
    # test enabled subscribe functionality
    CONFIG[:subscribe_url] = 'http://milkfarmproductions.createsend.com/t/r/s/ydgud/'
    get :subscribe
    assert_response :success
  end

  test "should_get_unsubscribe" do
    # test disabled unsubscribe functionality
    CONFIG[:unsubscribe_url] = nil
    get :unsubscribe
    assert_redirected_to root_path
    assert_equal 'Newsletter unsubscribe functionality is not enabled.', flash[:error]
    # test enabled unsubscribe functionality
    CONFIG[:unsubscribe_url] = 'http://milkfarmproductions.createsend.com/t/r/s/ydgud/'
    get :unsubscribe
    assert_response :success
  end
end
