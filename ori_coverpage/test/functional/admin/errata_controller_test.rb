require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ErrataControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :errata
  
  def setup
    @controller = Admin::ErrataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:errata)
  end

  test "should_search_index" do
    get :index, :search => { :name_like => 'John' }
    assert_response :success
    assert_not_nil assigns(:errata)
  end

  test "should_get_errata_for_product" do
    @product = products(:old)
    get :index, :product_id => @product.id
    assert_response :success
    assert_not_nil assigns(:errata)
    assert_equal assigns(:errata).map(&:id), @product.errata.map(&:id)
  end

  test "should_get_error_message_for_requesting_errata_of_invalid_product" do
    get :index, :product_id => Product.last.id + 1
    assert_redirected_to admin_errata_url
    assert flash[:error].include?('Error finding product')
  end


  test "should_get_index_as_xml" do
    @request.accept = 'application/xml'
    get :index
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    assert_not_nil assigns(:errata)
    assert_equal Erratum.all, assigns(:errata)
  end

  test "should_show_first_erratum" do
    get :show, :id => errata(:one).to_param
    assert_response :success
    assert_not_nil assigns(:erratum)
  end

  test "should_show_error_for_invalid_erratum_id" do
    get :show, :id => Erratum.last.id + 1
    assert_redirected_to admin_errata_url
    assert flash[:error].include?('Error finding erratum')
  end

  test "should get new" do
    get :new, :product_id => 1
    assert_response :success
  end

  test "should create erratum" do
    product_format = ProductFormat.find(2)
    assert_difference( Erratum, :count ) do
      post :create, :product_id => product_format.product.id, :erratum => { "product_format_id" => product_format.id, "erratum_type" => "Typo", "description" => "bad text", "page_number" => "99", "user_id" => @user.id  }
    end
    assert_redirected_to admin_errata_path
    assert 'Erratum was successfully created.', flash[:notice]
  end

  test "should_not_create_invalid_erratum" do
    product_format = ProductFormat.find(2)
    assert_difference( Erratum, :count, 0 ) do
      # missing erratum_type
      post :create, :product_id => product_format.product.id, :erratum => { "product_format_id" => product_format.id, "description" => "bad text", "page_number" => "99", "user_id" => @user.id  }
    end
    assert_response :success
    assert_template 'new'
    assert_not_equal 'Erratum was successfully created.', flash[:notice]
  end


  test "should_edit_erratum" do
    erratum = errata(:one)
    get :edit, :id => erratum.id
    assert_response :success
    assert_template 'edit'
  end

  test "should_update_erratum" do
    erratum = errata(:one)
    post :update, :id => erratum.id, :erratum => { :description => erratum.description.concat(" UPDATED") }
    assert_redirected_to admin_errata_url
    assert_equal 'Erratum was successfully updated.', flash[:notice]
  end

  test "should_not_update_erratum_with_errors" do
    erratum = errata(:one)
    post :update, :id => erratum.id, :erratum => { :description => "" }
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:erratum)
    assert assigns(:erratum).errors.collect { |field,error| "#{field} #{error}" }.include?("description can't be blank")
    assert_not_equal erratum.reload.description, assigns(:erratum).description
    assert_not_equal 'Erratum was successfully updated.', flash[:notice]
  end

  test "should destroy erratum" do
    assert_difference Erratum, :count, -1 do
      erratum = Erratum.first
      delete :destroy, :id => erratum
      assert_redirected_to admin_errata_url
      assert !Erratum.exists?(erratum.id)
    end
  end

  test "should_set_status" do
    put :set_status, :id => Erratum.first, :status => 'new'
    assert_response :redirect
    assert_not_nil assigns(:erratum)
    assert_redirected_to admin_erratum_path(assigns(:erratum))
    assert_equal "The status has been updated.", flash[:notice]
  end

  test "should_not_set_status_on_invalid_erratum" do
    put :set_status, :id => Erratum.last.id + 1, :status => 'new'
    assert_response :redirect
    assert_nil assigns(:erratum)
    assert_redirected_to admin_errata_path
    assert_not_equal "The status has been updated.", flash[:notice]
    assert_not_nil flash[:error]
  end

  test "should_get_format_options_js" do
    @request.accept = 'application/javascript'
    get :format_options, :product_id => Product.first.id
    assert_response :success
  end
end
