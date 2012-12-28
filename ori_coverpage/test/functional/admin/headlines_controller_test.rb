require File.dirname(__FILE__) + '/../../test_helper'

class Admin::HeadlinesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :headlines, :users

  def setup
    @controller = Admin::HeadlinesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert assigns(:headlines)
  end

  test "should_get_new" do
    get :new
    assert_response :success
  end
  
  test "should_create_headline" do
    assert_difference Headline, :count, 1 do
      post :create, :headline => { :title => 'MyString', :body => 'MyText' }
      assert_redirected_to admin_headlines_path
      assert_equal 'Headline was successfully created.', flash[:notice]
    end
  end

  test "should_fail_to_create_invalid_headline" do
    assert_difference Headline, :count, 0 do
      post :create, :headline => { :body => 'MyText' }
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:headline)
      assert assigns(:headline)
      #assert assigns(:headline).errors.each { |field,error| puts "#{field} -- #{error}"}
      assert assigns(:headline).errors.collect { |field,error| "#{field} #{error}" }.include?("title can't be blank") || assigns(:headline).errors.collect { |field,error| "#{field} #{error}" }.include?("title is too short (minimum is 3 characters)")
    end
  end

  test "should_show_headline" do
    get :show, :id => 1
    assert_response :success
  end

  test "should_get_edit" do
    get :edit, :id => 1
    assert_response :success
  end
  
  test "should_update_headline" do
    put :update, :id => 1, :headline => { }
    assert_redirected_to admin_headlines_path
    assert_equal 'Headline was successfully updated.', flash[:notice]
  end

  test "should_fail_to_update_invalid_headline" do
    assert_difference Headline, :count, 0 do
      put :update, :id => 1, :headline => { :title => nil }
      assert_response :success
      assert_template 'edit'
      assert_not_nil assigns(:headline)
      assert assigns(:headline).errors.collect { |field,error| "#{field} #{error}" }.include?("title can't be blank") || assigns(:headline).errors.collect { |field,error| "#{field} #{error}" }.include?("title is too short (minimum is 3 characters)")
    end
  end
  
  test "should_destroy_headline" do
    assert_difference Headline, :count, -1 do
      delete :destroy, :id => 1
      assert_redirected_to admin_headlines_path
    end
  end
end
