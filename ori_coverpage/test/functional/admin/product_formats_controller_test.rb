require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ProductFormatsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :contributors, :contributor_assignments

  def setup
    @controller   = Admin::ProductFormatsController.new
    @request      = ActionController::TestRequest.new
    @response     = ActionController::TestResponse.new
    @user         = login_as :admin
    @product      = Product.first
    @format       = Format.last
    @valid_isbn   = "9781610800570"
    @valid_isbn10 = "1610800575"
    @invalid_isbn = "1234567890123"
  end

  test "should_not_create_invalid_product_format" do
    assert_difference @product.product_formats, :count, 0 do
      post :create, :product_format => { :product_id => @product.id, :format_id => @format.id, :price_list => '100' }
      assert_response :redirect
      assert_redirected_to admin_product_url(@product)
      assert flash[:notice].include?("Record not saved:")
      assert flash[:notice].include?("Isbn can't be blank")
    end
  end

  test "should_not_create_invalid_product_format_js" do
    @request.accept = 'application/javascript'
    assert_difference @product.product_formats, :count, 0 do
      post :create, :product_format => { :product_id => @product.id, :format_id => @format.id, :price_list => '100' }
      assert_response :success
      assert @response.body.include?("alert")
      assert @response.body.include?("Record not saved:")
      assert @response.body.include?("Isbn can't be blank")
    end
  end

  test "create_valid_product_format" do
    assert_difference @product.product_formats, :count do
      post :create, :product_format => { :product_id => @product.id, :format_id => @format.id, :price_list => '100', :isbn => @valid_isbn }
      assert_response :redirect
      assert_redirected_to admin_product_url(@product)
      assert_equal "Product format was successfully created.", flash[:notice]
    end
  end

  test "create_valid_product_format_js" do
    @request.accept = 'application/javascript'
    assert_difference @product.product_formats, :count do
      post :create, :product_format => { :product_id => @product.id, :format_id => @format.id, :price_list => '100', :isbn => @valid_isbn }
      assert_response :success
      assert_not_nil assigns(:product_format)
      # check the response body for the expected javascript calls
      assert @response.body.include?("Element.insert")
      assert @response.body.include?(" id=\\\"#{ActionController::RecordIdentifier::dom_id(assigns(:product_format))}\\\"")
      assert @response.body.include?("new Effect.Highlight(\"#{ActionController::RecordIdentifier::dom_id(assigns(:product_format))}\",{});")
    end
  end

  test "should_not_create_duplicate_product_format" do
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference @product.product_formats, :count, 0 do
      post :create, :product_format => { :product_id => @product.id, :format_id => @product_format.format_id, :price_list => '100', :isbn => @valid_isbn }
      assert_response :redirect
      assert_redirected_to admin_product_url(@product)
      assert flash[:notice].include?("Record not saved: Format already exists.")
    end
  end

  test "should_not_create_duplicate_product_format_js" do
    @request.accept = 'application/javascript'
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference @product.product_formats, :count, 0 do
      post :create, :product_format => { :product_id => @product.id, :format_id => @product_format.format_id, :price_list => '100', :isbn => @valid_isbn }
      assert_response :success
      assert @response.body.include?("alert")
      assert @response.body.include?("Record not saved: Format already exists.")
    end
  end


  test "should_not_create_product_format_form_invalid_data" do
# TODO: try to find a parametering -- if possible -- to exploit the expected exception to increase coverage. if not possible, remove the corresponding code from the controller (dead code)
#    assert_difference @product.product_formats, :count, 0 do
#      assert_raise(ActiveRecord::StatementInvalid) do
#        post :create, :product_format => { :product_id => @product.id, :format_id => @format_id, :isbn => "123456789X" }
#        puts flash[:notice]
#      end
#    end
  end

  test "destroy_product_format" do
    @product = ProductFormat.last.product
    assert_difference ProductFormat, :count, -1 do
      delete :destroy, :id => ProductFormat.last.id
      assert_redirected_to admin_product_url(@product)
      assert_equal "Product format was deleted.", flash[:notice]
    end
  end

  test "destroy_product_format_js" do
    @request.accept = 'application/javascript'
    @product = ProductFormat.last.product
    assert_difference ProductFormat, :count, -1 do
      delete :destroy, :id => ProductFormat.last.id
      assert_response :success
      assert_not_nil assigns(:product_format)
      assert @response.body.include?("new Effect.Fade(\"#{ActionController::RecordIdentifier::dom_id(assigns(:product_format))}\",{duration:#{CONFIG[:fade_duration]}});")
    end
  end

  test "update_product_format" do
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference ProductFormat, :count, 0 do
      post :update, { :id => @product_format.id, :product_format => { :price_list => @product_format.price_list * 2 } }
      assert_redirected_to admin_product_url(@product)
      assert_equal "Product format was successfully updated.", flash[:notice]
      assert_not_equal @product_format.price_list, @product_format.reload.price_list
    end
  end

  test "update_product_format_js" do
    @request.accept = 'application/javascript'
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference ProductFormat, :count, 0 do
      post :update, { :id => @product_format.id, :product_format => { :price_list => @product_format.price_list * 2 } }
      assert_response :success
      # check response body for expected javascript code snippets
      assert_not_nil assigns(:product_format)
      assert @response.body.include?("new Effect.Highlight(\"#{ActionController::RecordIdentifier::dom_id(assigns(:product_format))}\",{});")
    end
  end

  test "invalid_update_product_format" do
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference ProductFormat, :count, 0 do
      post :update, { :id => @product_format.id, :product_format => { :isbn => '' } }
      assert_redirected_to admin_product_url(@product)
      assert flash[:notice].include?("Record not saved:")
      assert flash[:notice].include?("Isbn can't be blank")
      assert_equal @product_format.isbn, @product_format.reload.isbn
    end
  end

  test "invalid_update_product_format_js" do
    @request.accept = 'application/javascript'
    @product_format = ProductFormat.last
    @product = @product_format.product
    assert_difference ProductFormat, :count, 0 do
      post :update, { :id => @product_format.id, :product_format => { :isbn => '' } }
      assert_response :success
      assert @response.body.include?("Record not saved:")
      assert @response.body.include?("Isbn can't be blank")
      assert_equal @product_format.isbn, @product_format.reload.isbn
    end
  end
  
end
