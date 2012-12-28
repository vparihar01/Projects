require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ExcerptsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :excerpts, :products, :users

  def setup
    @controller = Admin::ExcerptsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:excerpts)
  end

  test "should_get_new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:excerpt)
    assert_template 'new'
  end

  test "should_create_excerpt" do
    assert_difference Excerpt, :count do
      post :create, :excerpt => {"filename"=>"test.txt", "title_id"=>products(:new).id}
      assert_redirected_to admin_excerpts_path
      assert_equal 'Excerpt was successfully created.', flash[:notice]
    end
  end

  test "should_not_create_invalid_excerpt" do
    assert_difference Excerpt, :count, 0 do
      post :create, :excerpt => {"filename"=>"test.txt"}
      assert_response :success
      assert_template 'new'
      assert_not_equal 'Excerpt was successfully created.', flash[:notice]
      assert_not_nil assigns(:excerpt)
      assert assigns(:excerpt).errors.collect { |field,error| "#{field} #{error}" }.include?("title_id can't be blank")
    end
  end

  test "should_show_excerpt" do
    get :show, :id => excerpts(:one).to_param
    assert_response :success
    assert_not_nil assigns(:excerpt)
  end

  test "should_handle_attempt_to_show_invalid_excerpt" do
    get :show, :id => Excerpt.all.last.id + 1
    assert_redirected_to admin_excerpts_url
    assert_nil assigns(:excerpt)
    assert_equal "Unknown ID", flash[:error]
  end

  test "should_get_edit" do
    get :edit, :id => excerpts(:one).to_param
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:excerpt)
  end

  test "should_update_excerpt" do
    #put :update, :id => excerpts(:one).to_param, :excerpt => { "title_id" => products(:future_title) }
    #assigns(:excerpt).errors.each { |field,error| puts "#{field} #{error}" } # debug
    #assert_redirected_to admin_excerpt_url(assigns(:excerpt))
  end

  test "should_destroy_excerpt" do
    excerpt = Excerpt.first
    assert_difference Excerpt, :count, -1 do
      delete :destroy, :id => excerpt
      assert_redirected_to admin_excerpts_url
      assert !Excerpt.exists?(excerpt.id)
    end
  end



end
