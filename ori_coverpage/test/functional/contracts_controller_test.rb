require File.dirname(__FILE__) + '/../test_helper'
require 'contracts_controller'

# Re-raise errors caught by the controller.
class ContractsController; def rescue_action(e) raise e end; end

class ContractsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :contracts, :sales_teams, :sales_zones, :users
  
  def setup
    @controller = ContractsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end
  
  test "should_create_valid_contract" do
    assert_difference Contract, :count do
      post :create, :contract => valid_contract
      assert_redirected_to contracts_url
      assert_equal 'The contract has been created.', flash[:notice]
    end
  end
  
  test "should_update_valid_contract" do
    @contract = contracts(:don_new_jersey)
    now = Time.now
    put :update, :id => @contract.id, 
      :contract => @contract.attributes.merge('end_on' => now.to_s)
    assert_redirected_to contract_url(@contract.id), assigns(:contract).errors.full_messages
    assert_equal 'The contract has been updated.', flash[:notice]
    assert_equal now.to_date, @contract.reload.end_on
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contracts)
  end

  test "should_show_contract" do
    @contract = Contract.first
    get :show, :id => @contract.id
    assert_response :success
    assert_not_nil assigns(:contract)
  end

  test "should_get_new" do
    get :new, :contract => valid_contract
    assert_response :success
    assert_not_nil assigns(:contract)
    assert_template 'new'
  end

end
