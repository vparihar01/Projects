require File.dirname(__FILE__) + '/../test_helper'
require 'faqs_controller'

# Re-raise errors caught by the controller.
class FaqsController; def rescue_action(e) raise e end; end

class FaqsControllerTest < ActionController::TestCase
  fixtures :faqs

  def setup
    @controller = FaqsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:faqs)
  end

  test "should_get_show" do
    get :show, :id => 1
    assert_response :success
    assert_not_nil assigns(:faq)
  end

  test "should_get_search" do
    get :search, :q => "game"
    assert_response :success
    assert_not_nil assigns(:faqs)
  end

  test "should_get_tagged_faqs" do
    get :tag, :tag => 'test'
    assert_response :success
    assert_not_nil assigns(:faqs)
  end

end
