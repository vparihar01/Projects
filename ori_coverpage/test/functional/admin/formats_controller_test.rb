require File.dirname(__FILE__) + '/../../test_helper'

class Admin::FormatsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :formats, :users
  
  def setup
    @format = Admin::FormatsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    login_as :admin
  end
  
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Format.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Format.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Format.any_instance.stubs(:valid?).returns(true)
    post :create
    assert assigns(:format)
    assert_redirected_to admin_formats_url
  end
  
  def test_edit
    get :edit, :id => Format.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Format.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Format.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Format.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Format.first
    assert assigns(:format)
    assert_redirected_to admin_formats_url
  end
  
  def test_destroy
    format = Format.first
    delete :destroy, :id => format
    assert_redirected_to admin_formats_url
    assert !Format.exists?(format.id)
  end

  test 'should_make_pdf_default_using_toggle_default' do
    @format = formats(:pdf)
    assert !@format.is_default
    put :toggle_default, :id => formats(:pdf).to_param
    assert_redirected_to admin_formats_url
    assert assigns(:format).is_default
  end

  test 'should_make_combo_pdf_using_toggle_pdf' do
    @format = formats(:combo)
    assert !@format.is_pdf
    put :toggle_pdf, :id => formats(:combo).to_param
    assert assigns(:format).is_pdf
  end
end
