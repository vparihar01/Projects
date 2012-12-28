require File.dirname(__FILE__) + '/../test_helper'

class TestimonialsControllerTest < ActionController::TestCase
  fixtures :testimonials
  
  def setup
    @controller = TestimonialsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    # no login, tests by anonymous
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
  end

  test "should_show_first_testimonial" do
    showroute = Coverpage::Application.routes.recognize_path("/testimonials/:id")
    assert_not_nil showroute
    if (showroute[:controller] == "testimonials")
      get :show, :id => testimonials(:one).to_param
      assert_response :success
      assert_not_nil assigns(:testimonial)
    else
      # TODO: print out a message that there is no route supporting this test case? or deprecate test case AND tested code
      assert true
    end
  end

  test "should_show_error_for_invalid_testimonial_id" do
    showroute = Coverpage::Application.routes.recognize_path("/testimonials/:id")
    assert_not_nil showroute
    if (showroute[:controller] == "testimonials")
      get :show, :id => Testimonial.last.id + 1
      assert_redirected_to testimonials_url
      assert flash[:error].include?('Error finding testimonial')
    else
      # TODO: print out a message that there is no route supporting this test case? or deprecate test case AND tested code
      assert true
    end
  end

end
