require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ContributorsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :contributors, :contributor_assignments

  def setup
    @controller = Admin::ContributorsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contributors)
  end

  test "should_search_index" do
    get :index, :search => { :name_like => 'brave'}
    assert_response :success
    assert_not_nil assigns(:contributors)
    assert assigns(:contributors).include?(contributors(:one)) # one brave
    assert assigns(:contributors).include?(contributors(:two)) # two braves
  end

  test "should_get_contributors_for_product" do
    @product = products(:old)
    get :index, :product_id => @product.id
    assert_response :success
    assert_not_nil assigns(:contributors)
  end

  test "regular_users_should_not_create_contributors" do
    login_as :quentin
    assert_no_difference Contributor, :count do
      post :create, :contributor => valid_contributor
      assert_response 404
    end
  end

  test "should_get_new_contributor_and_create" do
    get :new
    assert_response :success
    assert_template 'new'

    post :create                  # should respond with the new form
    assert_response :success
    assert_template 'new'
  end

  test "should_create_valid_contributor" do
    assert_difference Contributor, :count do
      post :create, :contributor => valid_contributor
      assert_equal 'Contributor was successfully created.', flash[:notice]
    end
  end

  test "should_get_edit_and_update" do
    contributor = Contributor.first
    get :edit, :id => contributor
    assert :success
    assert_not_nil assigns(:contributor)

    post :update, { :id => contributor.id, :contributor => { :name => contributor.name + "_updated" } }
    assert_redirected_to admin_contributors_path
    assert_equal "Contributor was successfully updated.", flash[:notice]
  end

  test "should_not_save_and_continue_editing_for_blank_name" do
    contributor = contributors(:one)
    post :update, { :id => contributor.id, :contributor => { :name => "" } }
    assert :success
    assert_template 'edit'
    assert_not_nil assigns(:contributor)
    assert assigns(:contributor).errors.collect { |field,error| "#{field} #{error}" }.include?("name can't be blank")
    assert_not_equal contributor.reload.name, assigns(:contributor).name
  end

  test "regular_users_should_not_destroy_contributors" do
    login_as :quentin
    assert_no_difference Contributor, :count do
      delete :destroy, :id => contributors(:one).to_param
      assert_response 404
    end
  end

  test "admin_should_destroy_contributor" do
    assert_difference Contributor, :count, -1 do
      delete :destroy, :id => contributors(:one).to_param
      assert_redirected_to admin_contributors_url
    end
  end


end
