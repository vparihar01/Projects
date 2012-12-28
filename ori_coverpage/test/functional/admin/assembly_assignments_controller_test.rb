require File.dirname(__FILE__) + '/../../test_helper'

class Admin::AssemblyAssignmentsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :assembly_assignments, :users, :products

  def setup
    @controller = Admin::AssemblyAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :admin
  end

  test "should_create_assembly_assignment" do
    assert_difference AssemblyAssignment, :count do
      post :create, :assembly_assignment => { :assembly_id => 4, :product_id => Product.last.id }
      assert_response :redirect
      assert_not_nil assigns(:assembly_assignment)
      assert_redirected_to admin_product_url(assigns(:assembly_assignment).assembly)
      assert_equal 'Assembly assignment was successfully created.', flash[:notice]
    end
  end

  test "should_create_assembly_assignment_js" do
    assert_difference AssemblyAssignment, :count do
      @request.accept = 'application/javascript'
      post :create, :assembly_assignment => { :assembly_id => 4, :product_id => Product.last.id }
      assert_response :success
      assert_not_nil assigns(:assembly_assignment)
      assert_equal assigns(:assembly_assignment).title, Product.last
      assert @response.body.include?("Element.insert")
      assert @response.body.include?(" id=\\\"#{ActionController::RecordIdentifier::dom_id(assigns(:assembly_assignment))}\\\"")
      assert @response.body.include?("new Effect.Highlight(\"#{ActionController::RecordIdentifier::dom_id(assigns(:assembly_assignment))}\",{});")
    end
  end

  test "should_not_create_assembly_assignment_with_missing_product" do
    assert_difference AssemblyAssignment, :count, 0 do
      post :create, :assembly_assignment => { :assembly_id => 4 }
      assert_response :redirect
      assert_not_nil assigns(:assembly_assignment)
      assert flash[:notice].include?('Your assembly assignment hasn\'t been saved,')
      assert flash[:notice].include?('Product can\'t be blank')
      assert_redirected_to admin_product_url(assigns(:assembly_assignment).assembly)
    end
  end

  test "should_not_create_assembly_assignment_with_missing_product_js" do
    assert_difference AssemblyAssignment, :count, 0 do
      @request.accept = 'application/javascript'
      post :create, :assembly_assignment => { :assembly_id => 4 }
      assert_response :success
      assert_not_nil assigns(:assembly_assignment)
      assert @response.body.include?('Your assembly assignment hasn\'t been saved,')
      assert @response.body.include?('Product can\'t be blank')
    end
  end
  
  test "should_destroy_assembly_assignment" do
    assert_difference AssemblyAssignment, :count, -1 do
      delete :destroy, :id => assembly_assignments(:new)
      assert_response :redirect
      assert_not_nil assigns(:assembly_assignment)
      assert_redirected_to admin_product_url(assigns(:assembly_assignment).assembly)
      assert_equal 'Assembly assignment was deleted.', flash[:notice]
    end
  end

  test "should_destroy_assembly_assignment_js" do
    assert_difference AssemblyAssignment, :count, -1 do
      @request.accept = 'application/javascript'
      delete :destroy, :id => assembly_assignments(:new)
      assert_response :success
      assert_not_nil assigns(:assembly_assignment)
      assert @response.body.include?("new Effect.Fade(\"#{ActionController::RecordIdentifier::dom_id(assigns(:assembly_assignment))}\",{duration:#{CONFIG[:fade_duration]}});")
    end
  end

end
