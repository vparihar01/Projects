require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :pages, :users, :headlines, :editorial_reviews

  def setup
    @controller = Admin::PagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_fail_to_get_index_if_not_admin" do
    @user = login_as nil
    get :index
    assert_response 404
  end

  test "should_get_index_as_admin" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pages)
  end

    test "regular_users_should_not_create_page" do
    @user = login_as :quentin
    assert_no_difference Page, :count do
      post :create, :page => valid_page
      assert_response 404
    end
  end

  test "should_test_if_new_page_forms_are_ok" do
    get :new
    assert_response :success
    assert_template 'new'

    post :create                  # should respond with the new form
    assert_response :success
    assert_template 'new'
  end

  test "should_create_valid_page" do
    assert_difference Page, :count do
      post :create, :page => valid_page
      assert_equal 'Page was successfully created.', flash[:notice]
    end
  end

  test "should_not_save_and_continue_editing_for_blank_title" do
    page = pages(:first)
    post :update, { :id => page.id, :page => { :title => "" } }
    assert :success
    assert_template 'edit'
    assert_not_nil assigns(:page)
    assert_not_equal page.reload.title, assigns(:page).title
    assert assigns(:page).errors.collect { |field,error| "#{field} #{error}" }.include?("title can't be blank")
  end


  test "should_test_edit_and_update" do
    page = Page.first
    get :edit, :id => page
    assert :success
    assert_not_nil assigns(:page)

    post :update, { :id => page.id, :page => { :title => page.title + "_updated" } }
    assert_redirected_to admin_pages_url
    assert_equal "Page was successfully updated.", flash[:notice]
  end

  test "admin_should_destroy_page" do
    assert_difference Page, :count, -1 do
      delete :destroy, :id => pages(:first).to_param
      assert_redirected_to admin_pages_url
    end
  end

  test "nobody_should_destroy_protected_page" do
    assert_no_difference Page, :count do
      delete :destroy, :id => pages(:protected).to_param
      assert_redirected_to admin_pages_url
      assert_equal "This page is protected and so cannot be deleted.", flash[:error]
    end
  end
end
