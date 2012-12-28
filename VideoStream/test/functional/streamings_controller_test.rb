require 'test_helper'

class StreamingsControllerTest < ActionController::TestCase
  setup do
    @streaming = streamings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:streamings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create streaming" do
    assert_difference('Streaming.count') do
      post :create, streaming: @streaming.attributes
    end

    assert_redirected_to streaming_path(assigns(:streaming))
  end

  test "should show streaming" do
    get :show, id: @streaming
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @streaming
    assert_response :success
  end

  test "should update streaming" do
    put :update, id: @streaming, streaming: @streaming.attributes
    assert_redirected_to streaming_path(assigns(:streaming))
  end

  test "should destroy streaming" do
    assert_difference('Streaming.count', -1) do
      delete :destroy, id: @streaming
    end

    assert_redirected_to streamings_path
  end
end
