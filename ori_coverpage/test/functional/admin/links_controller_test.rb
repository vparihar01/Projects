require File.dirname(__FILE__) + '/../../test_helper'

class Admin::LinksControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :links, :links_products, :users

  def setup
    @controller = Admin::LinksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:links)
  end

  test "should_show_first_link" do
    get :show, :id => links(:one).to_param
    assert_response :success
    assert_not_nil assigns(:link)
  end

  test "regular_users_should_not_create_link" do
    login_as :quentin
    assert_no_difference Link, :count do
      post :create, :link => valid_link
      assert_response 404
    end
  end

  test "should_test_if_new_link_forms_are_ok" do
    get :new
    assert_response :success
    assert_template 'new'

    post :create                  # should respond with the new form
    assert_response :success
    assert_template 'new'
  end


  test "should_not_create_link_with_invalid_url" do
    assert_no_difference Link, :count do
      post :create, :link => { :title => 'invalid link, no url' }
    end
  end


  test "should_create_valid_link" do
    assert_difference Link, :count do
      post :create, :link => valid_link
      assert_equal 'Link was successfully created.', flash[:notice]
    end
  end

  test "should_update_link" do
    link = Link.first
    get :edit, :id => link
    assert :success
    assert_not_nil assigns(:link)

    post :update, { :id => link.id, :link => { :title => link.title + "_updated" } }
    assert_redirected_to admin_links_path
    assert_equal "Link was successfully updated.", flash[:notice]
  end

  test "should_not_save_and_continue_editing_for_blank_url" do
    link = links(:one)
    post :update, { :id => link.id, :link => { :url => "" } }
    assert :success
    assert_template 'edit'
    assert_not_nil assigns(:link)
    assert assigns(:link).errors.collect { |field,error| "#{field} #{error}" }.include?("url can't be blank")
    assert_not_equal link.reload.url, assigns(:link).url
  end


  test "should_verify_product_assignments_functionality" do
    link = Link.first
    get :show, :id => link
    assert_response :success
    assert_not_nil assigns(:link)

    # delete product assignments
    assert_difference link.products, :count, assigns(:link).products.size*-1 do
      assigns(:link).products.each do |product|
        @request.accept = 'text/html'
        delete :delete_product, { :id => link.id, :product_id => product.id }
        assert_response :redirect
        assert_not_nil assigns(:link)
        assert_redirected_to edit_admin_link_url(assigns(:link))

        # now verify error -- relation deleted already, retry -> triggers ActiveRecord::RecordNotFound
        @request.accept = 'text/html'
        delete :delete_product, { :id => link.id, :product_id => product.id }
        assert_response :redirect
        assert_equal 'Product assignment was NOT deleted.', flash[:error]

      end
    end

    # add product assignments
    assert_difference link.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'text/html'
        post :assign_product, { :id => link.id, :product_id => product.id }
        assert_response :redirect
        assert_not_nil assigns(:link)
        assert_redirected_to edit_admin_link_url(assigns(:link))
      end
    end

  end

  test "should_verify_product_assignments_functionality_xml" do
    link = Link.first
    get :show, :id => link
    assert_response :success
    assert_not_nil assigns(:link)

    # delete product assignments
    assert_difference link.products, :count, assigns(:link).products.size*-1 do
      assigns(:link).products.each do |product|
        @request.accept = 'application/xml'
        delete :delete_product, { :id => link.id, :product_id => product.id }
        assert_response :success
      end
    end

    # add product assignments
    assert_difference link.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'application/xml'
        post :assign_product, { :id => link.id, :product_id => product.id }
        assert_response :success
      end
    end
  end

  test "should_verify_product_assignments_functionality_js" do
    link = Link.first
    get :show, :id => link
    assert_response :success
    assert_not_nil assigns(:link)

    # delete product assignments
    assert_difference link.products, :count, assigns(:link).products.size*-1 do
      assigns(:link).products.each do |product|
        @request.accept = 'application/javascript'
        delete :delete_product, { :id => link.id, :product_id => product.id }
        assert_response :success
        # now verify error -- relation deleted already, retry -> triggers ActiveRecord::RecordNotFound
        @request.accept = 'application/javascript'
        delete :delete_product, { :id => link.id, :product_id => product.id }
        assert_response :success
        assert @response.body.include?('alert("Product assignment was NOT deleted.")')

      end
    end

    # add product assignments
    assert_difference link.products, :count, Product.all.count do
      Product.all.each do |product|
        @request.accept = 'application/javascript'
        post :assign_product, { :id => link.id, :product_id => product.id }
        assert_response :success
      end
    end

  end


  test "admin_should_destroy_link" do
    assert_difference Link, :count, -1 do
      delete :destroy, :id => links(:one).to_param
      assert_redirected_to admin_links_url
    end
  end
end
