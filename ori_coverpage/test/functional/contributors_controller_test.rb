require File.dirname(__FILE__) + '/../test_helper'
require 'contributors_controller'

# Re-raise errors caught by the controller.
class ContributorsController; def rescue_action(e) raise e end; end

class ContributorsControllerTest < ActionController::TestCase
  fixtures :contributors, :products, :contributor_assignments
  
  def setup
    @controller = ContributorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  test "should_show_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contributors)
  end

  test "should_show_a_contributor" do
    get :show, :id => contributors(:one)
    assert_response :success
    assert_not_nil assigns(:contributor)
  end
end
