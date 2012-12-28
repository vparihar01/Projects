require File.dirname(__FILE__) + '/../test_helper'
require 'headlines_controller'

# Re-raise errors caught by the controller.
class HeadlinesController; def rescue_action(e) raise e end; end

class HeadlinesControllerTest < ActionController::TestCase
  fixtures :headlines

  def setup
    @controller = HeadlinesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert assigns(:headlines)
  end

  test "should_show_headline" do
    get :show, :id => 1
    assert_response :success
  end
end
