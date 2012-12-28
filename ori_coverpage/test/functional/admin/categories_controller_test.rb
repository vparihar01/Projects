require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CategoriesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :categories, :products, :categories_products, :users

  def setup
    @controller = Admin::CategoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  test "should_show_first_category_with_products" do
    get :show, :id => categories(:one).to_param
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should_test_if_new_category_forms_are_ok" do
    get :new
    assert_response :success
    assert_template 'new'

    post :create                  # should respond with the new form
    assert_response :success
    assert_template 'new'
  end

  test "should_create_a_new_category" do
    assert_difference Category, :count do
      post :create , { :category => { :name => "New Category" } }
      assert_redirected_to admin_categories_path
      assert_equal "Category was successfully created.", flash[:notice]
    end
  end

  test "should_test_edit_and_update" do
    category = Category.first
    get :edit, :id => category
    assert :success
    assert_not_nil assigns(:category)

    post :update, { :id => category.id, :category => { :name => category.name + "_updated" } }
    assert_redirected_to admin_categories_path
    assert_equal "Category was successfully updated.", flash[:notice]
  end

  test "should_not_save_and_continue_editing_for_duplicate_name" do
    category = categories(:one)
    post :update, { :id => category.id, :category => { :name => categories(:two).name } }
    assert :success
    assert_template 'edit'
    assert_not_nil assigns(:category)
    assert assigns(:category).errors.collect { |field,error| "#{field} #{error}" }.include?("name has already been taken")
    assert_not_equal category.reload.name, assigns(:category).name
  end

  test "should_verify_product_assignments_functionality" do
    category = Category.first
    get :show, :id => category
    assert_response :success
    assert_not_nil assigns(:products)

    # delete product assignments
    assert_difference category.products, :count, assigns(:products).size*-1 do
      assigns(:products).each do |product|
        @request.accept = 'text/html'
        delete :delete_product, { :id => category.id, :product_id => product.id }
        assert_equal 'Product assignment was successfully deleted.', flash[:notice]
        assert_response :redirect
        assert_not_nil assigns(:category)
        assert_redirected_to edit_admin_category_url(assigns(:category))
      end
    end

    # add product assignments
    assert_difference category.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'text/html'
        post :assign_product, { :id => category.id, :product_id => product.id }
        assert_response :redirect
      end
    end

  end

  test "should_verify_product_assignments_functionality_xml" do
    category = Category.first
    get :show, :id => category
    assert_response :success
    assert_not_nil assigns(:products)

    # delete product assignments
    assert_difference category.products, :count, assigns(:products).size*-1 do
      assigns(:products).each do |product|
        @request.accept = 'application/xml'
        delete :delete_product, { :id => category.id, :product_id => product.id }
        assert_response :success
      end
    end

    # add product assignments
    assert_difference category.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'application/xml'
        post :assign_product, { :id => category.id, :product_id => product.id }
        assert_response :success
      end
    end

  end

 test "should_verify_product_assignments_functionality_js" do
    category = Category.first
    get :show, :id => category
    assert_response :success
    assert_not_nil assigns(:products)

    # delete product assignments
    assert_difference category.products, :count, assigns(:products).size*-1 do
      assigns(:products).each do |product|
        @request.accept = 'application/javascript'
        delete :delete_product, { :id => category.id, :product_id => product.id }
        assert_response :success
      end
    end

    # add product assignments
    assert_difference category.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'application/javascript'
        post :assign_product, { :id => category.id, :product_id => product.id }
        assert_response :success
      end
    end

  end

  test "should destroy category" do
    assert_difference Category, :count, -1 do
      category = Category.first
      delete :destroy, :id => category
      assert_redirected_to admin_categories_url
      assert !Category.exists?(category.id)
    end
  end
end
