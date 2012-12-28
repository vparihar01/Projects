require File.dirname(__FILE__) + '/../test_helper'
require 'errata_controller'

class ErrataControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :errata, :sales_teams
  def setup
    @controller = ErrataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :dallas_schools
  end
  
  test "should_get_index" do
    # logout
    @request.session[:user] = nil
    get :index, :product_id => 1
    assert_response :success
    assert_not_nil assigns(:errata)
  end

  test "should_get_new" do
    get :new, :product_id => 1
    assert_response :success
  end

  test "should_create_erratum" do
    product_format = ProductFormat.find(2)
    assert_difference( Erratum, :count ) do
      post :create, :product_id => product_format.product.id, :erratum => { "product_format_id" => product_format.id, "erratum_type" => "Typo", "description" => "bad text", "page_number" => "99", "user_id" => @user.id  }
    end
    assert_redirected_to product_errata_path(product_format.product)
  end

  test "should_show_erratum" do
    get :show, :product_id => 1, :id => errata(:one).to_param
    assert_response :success
  end
end
