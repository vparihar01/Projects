require File.dirname(__FILE__) + '/../../test_helper'

class Admin::RecipientsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :recipients, :preferences
  setup do
    @recipient = recipients(:data_test)
    @controller = Admin::RecipientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:recipients)
  end

  test "should_get_new" do
    get :new
    assert_response :success
    assert_template 'new'
  end

  test "should_create_recipient" do
    assert_difference Recipient, :count, 1 do
      @recipient.name = "#{@recipient.name}_new"
      # merging with preference attributes to avoid errors from xxxRecipient validations on preferred_....
      post :create, :recipient => @recipient.attributes.merge(@recipient.preferences.inject({}) { |p,v| p.merge({ "preferred_#{v[0]}" => v[1] }) })
    end

    assert_redirected_to admin_recipients_path
    assert_equal 'Recipient was successfully created.', flash[:notice]
  end

  test "should_show_recipient" do
    get :show, :id => @recipient.to_param
    assert_response :success
  end

  test "should_get_edit" do
    get :edit, :id => @recipient.to_param
    assert_response :success
  end

  test "should_update_recipient" do
    put :update, :id => @recipient.to_param, :recipient => @recipient.attributes
    assert_redirected_to admin_recipients_path
    assert_equal 'Recipient was successfully updated.', flash[:notice]
  end

  test "should_destroy_recipient" do
    assert_difference Recipient, :count, -1 do
      delete :destroy, :id => @recipient.to_param
    end

    assert_redirected_to admin_recipients_path
  end
end
