require File.dirname(__FILE__) + '/../../test_helper'

class ContributorAssignmentsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :contributors, :contributor_assignments

  def setup
    @controller = Admin::ContributorAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end


  test "should_get_index" do
    get :index
    assert_response :success
  end

  test "should_not_get_index_as_nonadmin" do
    login_as :quentin
    get :index
    assert_response 404
  end

  test "should_check_new_contributor_assignment_form" do
    get :new
    assert_response :success
    assert_template 'new'
  end

  test "should_create_new_contributor_assignment" do
    assert_difference ContributorAssignment, :count do
      post :create, :contributor_assignment => valid_contributor_assignment
      assert_response :redirect
      assert_not_nil assigns(:contributor_assignment)
      assert_redirected_to admin_contributor_assignment_url(assigns(:contributor_assignment))
      assert_equal 'Contributor assignment was successfully created.', flash[:notice]
    end
  end

  test "should_create_new_contributor_assignment_js" do
    assert_difference ContributorAssignment, :count do
      @request.accept = 'application/javascript'
      post :create, :contributor_assignment => valid_contributor_assignment
      assert_response :success
      assert_not_nil assigns(:contributor_assignment)
      assert @response.body.include?("Element.insert")
      assert @response.body.include?(" id=\\\"#{ActionController::RecordIdentifier::dom_id(assigns(:contributor_assignment))}\\\"")
      assert @response.body.include?("new Effect.Highlight(\"#{ActionController::RecordIdentifier::dom_id(assigns(:contributor_assignment))}\",{});")
    end
  end

  test "should_not_create_new_contributor_assignment_with_missing_data" do
    assert_no_difference ContributorAssignment, :count do
      post :create, :contributor_assignment => { :contributor_id => 1, :product_id => 2, :role => ''}
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:contributor_assignment)
      assert assigns(:contributor_assignment).errors.collect { |field,error| "#{field} #{error}" }.include?("role is not included in the list")
      assert_not_equal 'Contributor assignment was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_new_contributor_assignment_with_missing_data_js" do
    assert_no_difference ContributorAssignment, :count do
      @request.accept = 'application/javascript'
      post :create, :contributor_assignment => { :contributor_id => 1, :product_id => 2, :role => ''}
      assert_response :success
      assert_not_nil assigns(:contributor_assignment)
      assert @response.body.include?('Your contributor assignment hasn\'t been saved,')
      assert @response.body.include?("#{assigns(:contributor_assignment).errors.full_messages}")
    end
  end

  test "should_check_edit_contributor_assignment_form" do
    get :edit, :id => contributor_assignments(:one).to_param
    assert_response :success
    assert_template 'edit'
    assert_not_nil  assigns(:contributor_assignment)
  end

  test "should_update_contributor_assignment" do
    contributor_assignment = contributor_assignments(:one)
    post :update, { :id => contributor_assignment.id, :contributor_assignment => { :role => "Photographer" } }
    assert_redirected_to admin_contributor_assignment_path(contributor_assignment.reload)
    assert_equal "Contributor assignment was successfully updated.", flash[:notice]
  end

  test "should_continue_editing_erroneous_update_to_contributor_assignment" do
    contributor_assignment = contributor_assignments(:one)
    post :update, { :id => contributor_assignment.id, :contributor_assignment => { :role => "Badmin" } } # submitting value not in list
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:contributor_assignment)
    assert assigns(:contributor_assignment).errors.collect { |field,error| "#{field} #{error}" }.include?("role is not included in the list")
    assert_not_equal "Contributor assignment was successfully updated.", flash[:notice]
  end


  test "should_destroy_contributor_assignment" do
    assert_difference ContributorAssignment, :count, -1 do
      delete :destroy, :id => contributor_assignments(:one).to_param
      assert_redirected_to admin_contributor_assignments_url
      assert_equal 'Contributor assignment was deleted.', flash[:notice]
    end
  end

  test "should_destroy_contributor_assignment_js" do
    assert_difference ContributorAssignment, :count, -1 do
      @request.accept = 'application/javascript'
      delete :destroy, :id => contributor_assignments(:one).to_param
      assert_response :success
      assert_not_nil assigns(:contributor_assignment)
      assert @response.body.include?("new Effect.Fade(\"#{ActionController::RecordIdentifier::dom_id(assigns(:contributor_assignment))}\",{duration:#{CONFIG[:fade_duration]}});")
    end
  end
end
