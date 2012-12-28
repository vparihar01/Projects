require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ProductsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :products, :product_formats, :users, :links, :links_products

  def setup
    @controller = Admin::ProductsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @user = login_as :admin
  end

  test "should_get_index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should_perform_search" do
    get :index, :q => "Old"
    assert_response :success
    assert_not_nil assigns(:search)
    assert_not_nil assigns(:products)
  end

  test "should_verify_link_assignments_functionality_js" do
    @request.accept = 'application/javascript'
    product = products(:old)
    get :edit, :id => product
    assert_response :success
    assert_not_nil assigns(:product)

    # delete product assignments
    assert_difference product.links, :count, assigns(:product).links.size*-1 do
      assigns(:product).links.each do |link|
        delete :delete_link, { :id => product.id, :link_id => link.id }
        assert_response :success
      end
    end

    # add product assignments
    assert_difference product.links, :count, Link.all.count do
      Link.all.each do |link|
        post :assign_link, { :id => product.id, :links_products => { :link_id => link.id } }
        assert_response :success
      end
    end
  end

  test "should_verify_link_assignments_functionality_html" do
    @request.accept = 'text/html'
    product = products(:old)
    get :edit, :id => product
    assert_response :success
    assert_not_nil assigns(:product)

    # delete product assignments
    assert_difference product.links, :count, assigns(:product).links.size*-1 do
      assigns(:product).links.each do |link|
        delete :delete_link, { :id => product.id, :link_id => link.id }
        assert_response :redirect
        assert_not_nil assigns(:product)
        assert_redirected_to edit_admin_product_url(assigns(:product))
      end
    end

    # add product assignments
    assert_difference product.links, :count, Link.all.count do
      Link.all.each do |link|
        post :assign_link, { :id => product.id, :links_products => { :link_id => link.id } }
        assert_response :redirect
        assert_not_nil assigns(:product)
        assert_redirected_to edit_admin_product_url(assigns(:product))
      end
    end
  end

  test "should_verify_link_assignments_error_handling" do
    # delete product assignments
    @request.accept = 'text/html'
    delete :delete_link, { :id => Product.last.id+1, :link_id => 1 }
    assert_response :redirect
    assert_nil assigns(:product)
    assert_redirected_to admin_products_url
    assert_equal "Link assignment was NOT deleted.", flash[:error]

    @request.accept = 'application/javascript'
    delete :delete_link, { :id => Product.last.id+1, :link_id => 1 }
    assert_response :success
    assert_nil assigns(:product)
    assert @response.body.include?("Link assignment was NOT deleted.")

    @request.accept = 'application/xml'
    delete :delete_link, { :id => Product.last.id+1, :link_id => 1 }
    assert_response :unprocessable_entity
    assert_nil assigns(:product)
    assert @response.body.include?("Link assignment was NOT deleted.")


    # add product assignments
    @request.accept = 'text/html'
    post :assign_link, { :id => Product.last.id + 1, :links_products => { :link_id => Link.first.id } }
    assert_response :redirect
    assert_redirected_to admin_products_url

    @request.accept = 'application/javascript'
    post :assign_link, { :id => Product.last.id + 1, :links_products => { :link_id => Link.first.id } }
    assert_response :success
    assert @response.body.include?("The Link could not be assigned.")

    @request.accept = 'application/xml'
    post :assign_link, { :id => Product.last.id + 1, :links_products => { :link_id => Link.first.id } }
    assert_response :unprocessable_entity
    assert @response.body.include?("The Link could not be assigned.")

    # TODO: repeat tests with invalid link id (and valid product id) to make sure...
  end

  test "should_verify_unique_product_link_assignments" do
    # uncomment this test case if unique product-link assignments is not implemented on purpose
    product = products(:old)

    post :assign_link, { :id => product.id, :links_products => { :link_id => Link.first.id } }
    #assert_response :success
    assert_response :redirect
    assert_redirected_to  edit_admin_product_url(product)
    # this

    post :assign_link, { :id => product.id, :links_products => { :link_id => Link.first.id } }
    #assert_response :success
    assert_response :redirect
    assert_redirected_to  edit_admin_product_url(product)
    #redirect_to @product.nil? ? admin_products_url : edit_admin_product_url(@product)
    # test case should have failed, in case the intention is -- that should be i guess --
    # to have unique product_id - link_id pairs in links_products
    # (the :uniq => true directive of has_and_belongs_to_many does not provide this 'validation')
    # TODO fix up code; if needed, see comment above

  end

  test "should_show_product" do
    get :show, :id => Product.first.id
    assert_not_nil assigns(:product)
    assert_redirected_to show_path(assigns(:product))
  end

  test "should_attempt_to_destroy_invalid_product" do
    assert_difference Product, :count, 0 do
      delete :destroy, :id => Product.last.id + 1
      assert_nil assigns(:product)
      assert_redirected_to admin_products_path
      assert "Unknown ID : Couldn't find Product with ID=#{Product.last.id + 1}", flash[:error]
    end
  end

  test "should_fail_import_without_file" do
    post :import
    assert_response :success
    assert_equal "Please select a file.", flash.now[:error]
    assert_template 'import'
  end

  test "should_pass_import" do
    post :import, :import => { :uploaded_data => fixture_file_upload('files/products.txt', 'text/csv'), :synchronous => '1' }
    assert_response :redirect
  end

  test "should_pass_import_when_background" do
    assert_difference Delayed::Job, :count, 1 do
      post :import, :import => { :uploaded_data => fixture_file_upload('files/products.txt', 'text/csv'), :synchronous => '0' }
      assert_response :redirect
    end
    assert_match /Your request has been/, flash.now[:notice]
  end
  
  test "should_fail_import_with_bad_data" do
    post :import, :import => { :uploaded_data => fixture_file_upload('files/products-bad.txt', 'text/csv'), :synchronous => '1' }
    assert_response :success
    assert_template 'import'
    assert_match /Import failed/, flash.now[:error]
  end

  test "should_pass_import_with_bad_data_when_background" do
    assert_difference Delayed::Job, :count, 1 do
      post :import, :import => { :uploaded_data => fixture_file_upload('files/products-bad.txt', 'text/csv'), :synchronous => '0' }
      assert_response :redirect
    end
    assert_match /Your request has been/, flash.now[:notice]
  end

  test "should_get_export_form" do
    get :export
    assert_response :success
    assert_template 'export'
  end

  test "should_get_export_form_if_missing_mandatory_format_ids" do
    post :export
    assert_response :success
    assert_equal "Please select at least one Product Format.", flash.now[:error]
    assert_template 'export'
  end

  test "should_get_export_form_if_missing_mandatory_template" do
    post :export, :data_format_ids => [Format::DEFAULT_ID.to_s]
    assert_response :success
    assert_equal "Please select a template.", flash.now[:error]
    assert_template 'export'
  end

  test "should_get_export_form_if_wrong_template" do
    post :export, :data_format_ids => [Format::DEFAULT_ID.to_s], :data_template => 'invalidstring'
    assert_response :success
    assert_equal "Please select a template.", flash.now[:error]
    assert_template 'export'
  end

  test "should_export_standard_template" do
    template = 'standard'
    assert ProductsExporter::TEMPLATES.keys.include?(template)
    post :export, :klass => 'Product', :data_format_ids => [Format::DEFAULT_ID.to_s], :data_template => template
    assert_response :success
    assert_equal "binary", @response.header['Content-Transfer-Encoding']
    assert_equal "text/csv", @response.header['Content-Type']
    assert_equal "attachment; filename=\"#{CONFIG[:export_basename]}-#{template}-#{Time.now.strftime("%Y%m%d")}.csv\"", @response.header['Content-Disposition']
    body = @response.body
    header = body.split("\n").first.gsub('"', '').split(",")
    assert_equal header, ProductsExporter.send("#{template}_header")
    record1 = body.split("\n")[1].gsub('"', '').split(",")
    assert_equal record1[0].to_i, product_formats(:future_title_paper).id  # :future_title is the alphabetically first record in products.yml
  end

  test "should_get_export_form_if_wrong_start_date" do
    post :export, :data_format_ids => [Format::DEFAULT_ID.to_s], :start_date => 'invalidstring'
    assert_response :success
    assert_equal "Start date must be formatted as YYYY-MM-DD.", flash.now[:error]
    assert_template 'export'
  end

  test "should_get_export_form_if_wrong_end_date" do
    post :export, :data_format_ids => [Format::DEFAULT_ID.to_s], :end_date => 'invalidstring'
    assert_response :success
    assert_equal "End date must be formatted as YYYY-MM-DD.", flash.now[:error]
    assert_template 'export'
  end

  # when user changes product select dropdown
  test "should select JS" do
    Product::SELECT_PARTIALS.each do |partial|
      @request.accept = 'application/javascript'
      get :select, :product_select => partial
      assert_response :success
      # TODO verify page updates
    end

    get :select, :product_select => 'INVALID'
    assert_response :success
    # TODO verify page updates
  end

  # when user changes product select dropdown
  test "should select HTML" do
    Product::SELECT_PARTIALS.each do |partial|
      get :select, :product_select => partial
      assert_response :redirect
      assert_redirected_to admin_distribution_path(:product_select => partial)
    end

    get :select, :product_select => 'INVALID'
    assert_response :redirect
    assert_redirected_to admin_distribution_path(:product_select => 'INVALID')
  end
end
