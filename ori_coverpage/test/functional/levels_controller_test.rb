require File.dirname(__FILE__) + '/../test_helper'

class LevelsControllerTest < ActionController::TestCase
  fixtures :products, :levels

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:levels)
  end

  test "should_show_level" do
    get :show, :id => levels(:preschool).to_param
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should_fail_on_unknown_level" do
    assert_raise(ActiveRecord::RecordNotFound) do
      get :show, :id => "blahblah"
    end
  end
end
