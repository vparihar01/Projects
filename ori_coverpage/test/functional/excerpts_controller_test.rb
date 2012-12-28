require File.dirname(__FILE__) + '/../test_helper'

class ExcerptsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :excerpts, :products, :users

  def setup
    @controller = ExcerptsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login, anonymous by default
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:excerpts)
  end

  test "should_click_excerpt" do
    #TODO: fix up test data / test case for file download (no file is present causing missing file exception)
    #put :click, :id => excerpts(:one).id.to_param
    #assert_response :success
    #assert_not_nil assigns(:excerpt)
  end

  test "should_read_excerpt" do
    put :read, :id => excerpts(:one).id.to_param
    assert_response :success
    assert_not_nil assigns(:excerpt)
  end

  test "attempt_to_read_invalid_excerpt_should_be_handled" do
    put :read, :id => Excerpt.last.id + 1
    assert_redirected_to excerpts_url
    assert_equal "Unknown ID", flash[:error]
  end

end
