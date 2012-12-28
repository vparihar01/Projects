require File.dirname(__FILE__) + '/../test_helper'

class SalesRepsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :sales_teams

  def setup
    @controller = SalesRepsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:quentin)
  end

  test "should_get_new_as_admin" do
    login_as(:admin)
    get :new, :sales_team_id => 1 
    assert_response :success
  end
  
  test "should_not_get_new_as_non_admin" do
    get :new, :sales_team_id => 1 
    assert_redirected_to login_url
  end

  test "should_create_user_as_admin" do
    login_as(:admin)
    assert_difference User, :count do
      post :create, :sales_team_id => 1, :sales_rep => valid_user
    end
    
    assert_redirected_to sales_team_sales_rep_path(sales_teams(:dan), assigns(:sales_rep))
    assert_equal 1, User.order('created_at DESC').first.sales_team_id
  end
  
  test "should_not_create_user_as_non_admin" do
    assert_no_difference User, :count do
      post :create, :sales_team_id => 1, :sales_rep => valid_user
    end
    
    assert_redirected_to login_url
  end
  
  test "should_not_create_invalid_user" do
    login_as(:admin)
    assert_no_difference User, :count do
    #assert_no_difference User, :count do
      post :create, :sales_team_id => 1, :sales_rep => valid_user.merge(:name => nil)
    end
    
    #assert assigns(:user).errors.on(:name)
    assert assigns(:sales_rep).errors[:name]
    assigns(:sales_rep).errors.full_messages.each do |message|
      assert_tag :li, :content => message
    end
  end

  test "should_show_user" do
    get :show, :sales_team_id => 1, :id => 1
    assert_response :success
    assert_equal users(:quentin), assigns(:sales_rep)
  end
  
  test "should_not_show_edit_link_as_non_admin" do
    get :show, :sales_team_id => 1, :id => 1
    assert_no_tag :a, :content => 'Edit sales rep'
  end
  
  # test "should_show_edit_link_as_admin
  #   login_as(:admin)
  #   get :show, :sales_team_id => 1, :id => 1
  #   assert_tag :a, :content => 'Edit sales rep'
  # end

  test "should_get_edit_as_admin" do
    login_as(:admin)
    get :edit, :sales_team_id => 1, :id => 1
    assert_response :success
    assert_equal users(:quentin), assigns(:sales_rep)
  end
  
  test "should_not_get_edit_as_non_admin" do
    get :edit, :sales_team_id => 1, :id => 1
    assert_redirected_to login_url
  end
  
  test "should_not_be_able_show_user_from_other_team" do
    assert_raise(ActiveRecord::RecordNotFound) { 
      get :show, :sales_team_id => 1, :id => 4 
    }
    assert_raise(ActiveRecord::RecordNotFound) { 
      get :show, :sales_team_id => 2, :id => 4 
    }
  end
  
  test "should_update_use_as_admin" do
    login_as(:admin)
    put :update, :sales_team_id => 1, :id => 1, :sales_rep => { :name => 'Bob' }
    assert_redirected_to sales_team_sales_rep_path(sales_teams(:dan), assigns(:sales_rep))
    assert_equal 'Bob', User.find(1).name
  end
  
  test "should_not_update_user_as_non_admin" do
    put :update, :sales_team_id => 1, :id => 1, :sales_rep => { :name => 'Bob' }
    assert_redirected_to login_url
  end
  
  test "should_destroy_user_as_admin" do
    login_as(:admin)
    assert_difference User, :count, -1 do
      delete :destroy, :sales_team_id => 1, :id => 1
    end
    
    assert_redirected_to sales_team_path(sales_teams(:dan))
  end
  
  test "should_not_destroy_user_as_non_admin" do
    assert_no_difference User, :count do
      delete :destroy, :sales_team_id => 1, :id => 1
    end
    
    assert_redirected_to login_url
  end
  
  
  protected
    
    def valid_user
      { :name => 'Bob', :password => 'test', :password_confirmation => 'test', :email => 'foo@foo.com' }
    end
end
