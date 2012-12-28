require File.dirname(__FILE__) + '/../test_helper'

class SalesTeamsControllerTest < ActionController::TestCase
  include ActionView::Helpers::NumberHelper
  include AuthenticatedTestHelper
  
  fixtures :users, :sales_teams, :sales_targets, :posted_transactions

  def setup
    @controller = SalesTeamsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as(:admin)
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert assigns(:sales_teams)
    assert_template 'index'
  end

  # TODO: uncomment this test case once routing TODO has been fixed
  test "should_get_show_as_index_for_non_admin" do
#    login_as(:quentin)
#    get :index
#    follow_redirect
#    assert_equal users(:quentin).sales_team, assigns(:sales_team)
#    assert_template 'show'
  end

  test "should_get_new" do
    get :new
    assert_response :success
  end
  
  test "new_should_redirect_to_login_for_non_admin" do
    login_as(:quentin)
    get :new
    assert_redirected_to login_url
  end
  
  test "should_create_sales_team" do
    old_count = SalesTeam.count
    post :create, :sales_team => { :name => 'New team', :address_attributes => {:street => '123 Main St.', :city => 'Kings Beach', :country_id => '223'} }, :postal_code => {:name => '96143', :zone_id => '1'}
    assert_equal old_count+1, SalesTeam.count
    assert_redirected_to sales_team_path(assigns(:sales_team))
  end

  test "should_show_sales_team" do
    get :show, :id => 2
    assert_response :success
    assert_equal 2, assigns(:sales_team).id
  end
  
  test "show_only_own_sales_team_for_non_admin" do
    login_as(:quentin)
    get :show, :id => 2
    assert_template 'show'
    assert_equal 1, assigns(:sales_team).id
  end

  # TODO: uncomment this test case once routing TODO has been fixed
  test "should_not_show_edit_links_to_non_admin" do
#    login_as(:quentin)
#    get :show
#    assert_template 'show'
#    assert_equal 1, assigns(:sales_team).id
#    assert_no_tag :a, :content => 'Edit team'
#    assert_no_tag :a, :content => 'Create a new sales rep'
  end

  # This test case was commented out already
  # test "should_show_edit_links_to_admin" do
  #   get :show, :id => 1
  #   assert_template 'show'
  #   assert_equal 1, assigns(:sales_team).id
  #   assert_tag :a, :content => 'Edit team'
  #   assert_tag :a, :content => 'Create a new sales rep'
  # end
  
  test "should_get_edit" do
    get :edit, :id => sales_teams(:dan)
    assert_response :success
  end
  
  test "should_update_sales_team" do
    put :update, :id => 1, :sales_team => { :name => 'test', :address_attributes => {:street => '123 Main St.', :city => 'Kings Beach', :country_id => '223'} }, :postal_code => {:name => '96143', :zone_id => '1'}
    assert_redirected_to sales_team_path(assigns(:sales_team))
  end
  
  test "should_fail_to_update_sales_team" do
    put :update, :id => 1, :sales_team => { :address_attributes => {:street => '123 Main St.', :city => 'Kings Beach', :country_id => '223'} }, :postal_code => {:name => '96143', :zone_id => '1'}
    assert_not_nil assigns(:sales_team).errors
    assert_template 'edit'
  end
  
  test "should_show_search_results" do
    get :index, :q => 'conner'
    assert assigns(:sales_teams).include?(sales_teams(:dan))
    assert !assigns(:sales_teams).include?(sales_teams(:bobby))
  end
  
  test "ytd_sales" do
    @team = sales_teams(:dan)
    assert_not_nil(amount = @team.posted_transactions.first.transaction_amount)
    
    get :ytd_sales, :id => @team.id
    assert_select "td#current_ytd_sales", number_to_currency(amount)
  end
end
