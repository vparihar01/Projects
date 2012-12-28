require File.dirname(__FILE__) + '/../../test_helper'

class Admin::TestimonialsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :testimonials, :users

  def setup
    @controller = Admin::TestimonialsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:testimonials)
  end

  test "should_get_index_as_xml" do
    @request.accept = 'application/xml'
    get :index
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    assert_not_nil assigns(:testimonials)
    assert_equal Testimonial.all, assigns(:testimonials)
  end

  test "should_show_first_testimonial" do
    get :show, :id => testimonials(:one).to_param
    assert_response :success
    assert_not_nil assigns(:testimonial)
  end

  test "should_show_error_for_invalid_testimonial_id" do
    get :show, :id => Testimonial.last.id + 1
    assert_redirected_to admin_testimonials_url
    assert flash[:error].include?('Error finding testimonial')
  end

  test "should_check_new_testimonial_form" do
    get :new
    assert_response :success
    assert_not_nil assigns(:testimonial)
    assert_template 'new'
  end

  test "should_create_new_testimonial" do
    assert_difference Testimonial, :count do
      post :create, :testimonial => valid_testimonial
      assert_not_nil assigns(:testimonial)
      assert_redirected_to admin_testimonials_url
      assert_equal 'Testimonial was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_new_testimonial_with_errors" do
    assert_difference Testimonial, :count, 0 do
      (invalid_testimonial = valid_testimonial)['comment'] = ""
      post :create, :testimonial => invalid_testimonial
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:testimonial)
      assert assigns(:testimonial).errors.collect { |field,error| "#{field} #{error}" }.include?("comment can't be blank")
      assert_not_equal 'Testimonial was successfully created.', flash[:notice]
    end
  end

  test "should_edit_testimonial" do
    testimonial = testimonials(:one)
    get :edit, :id => testimonial.id
    assert_response :success
    assert_template 'edit'
  end

  test "should_update_testimonial" do
    testimonial = testimonials(:one)
    post :update, :id => testimonial.id, :testimonial => { :comment => testimonial.comment.concat(" UPDATED") }
    assert_redirected_to admin_testimonials_url
    assert_equal 'Testimonial was successfully updated.', flash[:notice]
  end

  test "should_not_update_testimonial_with_errors" do
    testimonial = testimonials(:one)
    post :update, :id => testimonial.id, :testimonial => { :comment => "" }
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:testimonial)
    assert assigns(:testimonial).errors.collect { |field,error| "#{field} #{error}" }.include?("comment can't be blank")
    assert_not_equal testimonial.reload.comment, assigns(:testimonial).comment
    assert_not_equal 'Testimonial was successfully updated.', flash[:notice]
  end


  test "should_destroy_testimonial" do
    assert_difference Testimonial, :count, -1 do
      delete :destroy, :id => Testimonial.last.id
      assert_redirected_to admin_testimonials_url
      assert_equal 'Testimonial was successfully deleted.', flash[:notice]
    end
  end

  test "should_show_error_for_delete_attempt_on_invalid_testimonial_id" do
    assert_difference Testimonial, :count, 0 do
      delete :destroy, :id => Testimonial.last.id + 1
      assert_redirected_to admin_testimonials_url
      assert flash[:error].include?('Error finding testimonial')
    end
  end
end
