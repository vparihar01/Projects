require File.dirname(__FILE__) + '/../test_helper'

# tesing standard rails testing
class SpecsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :specs, :users

  def setup
    @spec = Spec.find(1)
    @user = login_as :admin
  end

  test "should_get_index" do
    @spec = Spec.find(1)
    @user = login_as :admin
    get :edit, :id => @spec.id
    assert_response :success
  end

  test "should_not_be_displayed_for_another_user" do
    @spec = Spec.find(2)
    assert_not_equal @spec.specable, @user
    get :show, :id => @spec.id
    assert_redirected_to specs_url
  end

  test "should_be_displayed_for_current_user" do
    assert_equal @spec.specable, @user
    get :show, :id => @spec.id
    assert_redirected_to edit_spec_url(@spec)
  end

  test "should_show_the_new_form_for_the_new_action_by_default" do
    get :new
    assert_template 'new'
  end

  test "should_redirect_to_spec_list_after_creation" do
    post :create, :spec => @spec.attributes
    assert_redirected_to specs_url
  end

  test "should_redirect_to_checkout_after_creation_in_context" do
    post :create, :context => 'checkout', :spec => @spec.attributes
    assert_redirected_to checkout_processing_url
  end

  test "should_show_the_edit_form_for_the_edit_action_by_default" do
    get :edit, :id => @spec.id
    assert_template 'edit'
  end

  test "should_redirect_to_spec_list_after_update" do
    post :update, :id => @spec.id, :spec => @spec.attributes
    assert_redirected_to specs_url
  end

  test "should_redirect_to_checkout_after_update_in_context" do
    post :update, :context => 'checkout', :id => @spec.id, :spec => @spec.attributes
    assert_redirected_to checkout_processing_url
  end
end
