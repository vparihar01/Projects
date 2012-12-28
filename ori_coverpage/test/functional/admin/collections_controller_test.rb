require File.dirname(__FILE__) + '/../../test_helper'


class Admin::CollectionsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :collections

  def setup
    @controller = Admin::CollectionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
    @collection = collections(:two)
  end

  test "assign_product" do
    @request.accept = 'text/html'
    @product = products(:recent)
    get :assign_product, :id => @collection.to_param, :product_id => @product.to_param
    assert_response :redirect
    assert_redirected_to edit_admin_collection_url(@collection)
    assert_nil flash[:error]
    assert_equal 'Product was successfully assigned.', flash[:notice]
    assert_equal @collection, @product.reload.collection
  end

  test "assign_product_js" do
    @request.accept = 'application/javascript'
    @product = products(:recent)
    get :assign_product, :id => @collection.to_param, :product_id => @product.to_param
    assert_response :success
    assert @response.body.include?("new Effect.Highlight(\"#{ActionController::RecordIdentifier::dom_id(@product)}\",{});")
    assert_equal @collection, @product.reload.collection
  end

  test "assign_not_existing_product" do
    @request.accept = 'text/html'
    get :assign_product, :id => @collection.to_param, :product_id => Product.last.id + 1
    assert_response :redirect
    assert_redirected_to edit_admin_collection_url(@collection)
    assert_equal "The product could not be assigned - Couldn't find Product with ID=#{Product.last.id+1}", flash[:error]
  end

  test "assign_not_existing_product_js" do
    @request.accept = 'application/javascript'
    get :assign_product, :id => @collection.to_param, :product_id => Product.last.id + 1
    assert_response :success
    assert @response.body.include?("alert(\"The product could not be assigned - Couldn't find Product with ID=#{Product.last.id+1}\");")
  end

  test "delete_product" do
    @request.accept = 'text/html'
    get :delete_product, :id => @collection.to_param, :product_id => products(:future_title).to_param
    assert_response :redirect
    assert_redirected_to edit_admin_collection_url(@collection)
  end

  test "delete_product_js" do
    @request.accept = 'application/javascript'
    get :delete_product, :id => @collection.to_param, :product_id => products(:future_title).to_param
    assert_response :success
  end

  test "delete_product_failure_on_not_collection_member_product" do
    @request.accept = 'text/html'
    @product = products(:no_format_record)
    get :delete_product, :id => @collection.to_param, :product_id => @product.to_param
    assert_response :redirect
    assert_redirected_to edit_admin_collection_url(@collection)
    assert_equal "Product assignment was NOT deleted - Couldn't find Product with ID=#{@product.id} [WHERE (`products`.collection_id = #{@collection.id})]", flash[:error]
  end

  test "delete_product_failure_on_not_collection_member_product_js" do
    @request.accept = 'application/javascript'
    @product = products(:no_format_record)
    get :delete_product, :id => @collection.to_param, :product_id => @product.to_param
    assert_response :success
    assert @response.body.include?("alert(\"Product assignment was NOT deleted - Couldn't find Product with ID=#{@product.id} [WHERE (`products`.collection_id = #{@collection.id})]\");")
  end
end
