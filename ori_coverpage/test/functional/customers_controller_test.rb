require File.dirname(__FILE__) + '/../test_helper'
require 'customers_controller'

# Re-raise errors caught by the controller.
class CustomersController; def rescue_action(e) raise e end; end

class CustomersControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :posted_transactions
  
  def setup
    @controller = CustomersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  test "should_show_all_customers_to_admin" do
    login_as :admin
    get :index
    assert_equal Customer.count, assigns(:customers).size
  end

  # Test case commented out due to sales teams functionality is not used in this project (it is for childsworld)
  # so there is no code to back up this test (no checks on the sales team in customer_controller index
  # TODO deal with this test case once childsworld & cherrylake have been merged completely and use of salesteams has been transformed to a switchable option for the project
  #test "should_show_only_customers_for_team_to_sales_rep" do
  #  login_as :quentin
  #  get :index
  #  assert_equal [ users(:dallas_schools) ], assigns(:customers)
  #end
  
  test "should_show_customer_to_admin" do
    login_as :admin
    get :show, :id => users(:mobile_schools).id
    assert_template 'show'
    assert_equal users(:mobile_schools), assigns(:customer)
  end
  
  test "should_not_show_non_team_customer_to_sales_rep" do
    login_as :quentin
    assert_raise(ActiveRecord::RecordNotFound) { 
      get :show, :id => users(:mobile_schools).id
    }
  end
  
  test "should_create_valid_customer" do
    login_as :admin
    assert_difference Customer, :count do
      post :create, :customer => valid_customer
    end
    assert_redirected_to :action => "index"
    assert_equal "The customer has been created.", flash[:notice]
  end
  
  test "should_update_valid_customer" do
    login_as :admin
    @customer = users(:dallas_schools)
    put :update, :id => @customer.id, :customer => @customer.attributes.merge('name' => 'Foo')
    assert_redirected_to :action => "show", :id => @customer.id
    assert_equal "The customer has been updated.", flash[:notice]
    assert_equal 'Foo', @customer.reload.name
  end
  
  test "should_not_create_valid_customer_by_non_admin" do
    login_as :quentin
    assert_no_difference Customer, :count do
      post :create, :customer => valid_customer
    end
    assert_redirected_to login_url
  end
  
  test "should_not_update_valid_customer_by_non_admin" do
    login_as :quentin
    @customer = users(:dallas_schools)
    put :update, :id => @customer.id, :customer => @customer.attributes.merge('name' => 'Foo')
    assert_redirected_to login_url
    assert_not_equal 'Foo', @customer.reload.name
  end
  
  test "should_show_search_results" do
    login_as :admin
    get :index, :q => 'dallas'
    assert assigns(:customers).include?(users(:dallas_schools))
    assert !assigns(:customers).include?(users(:mobile_schools))
  end

  test "should_get_purchased_products_for_user" do
    @user = login_as :admin
    @customer = users(:mobile_schools)
    get :products, :id => @customer.id
    assert_response :success
    assert_equal "Purchased Products - #{@customer.name} - Customers", assigns(:page_title)
    assert_not_nil assigns(:purchases)

    # 2nd test case (to reach 100% CC on :products method) -- provide filters for building different SQL query
    get :products, :id => @customer.id, :reading_level_id => 1, :category_id => 1
    assert_response :success
    assert_equal "Purchased Products - #{@customer.name} - Customers", assigns(:page_title)
  end
end
