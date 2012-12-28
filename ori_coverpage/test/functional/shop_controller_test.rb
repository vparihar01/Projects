require File.dirname(__FILE__) + '/../test_helper'
require 'shop_controller'

# Re-raise errors caught by the controller.
class ShopController; def rescue_action(e) raise e end; end

class ShopControllerTest < ActionController::TestCase
  include ActionView::Helpers::NumberHelper
  include AuthenticatedTestHelper
  fixtures :users, :products, :product_formats, :line_items, :line_item_collections, :assembly_assignments, :discounts
  
  def setup
    @controller = ShopController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    #@user = login_as :admin
    @user = login_as :aaron
    @product = Product.find(2)
    @product_format = @product.product_formats[0]
  end

  test "should_handle_requests_for_invalid_products" do
    assert_raise(ActiveRecord::RecordNotFound) do
      get :show, :id => Product.last.id + 1
      #assert_response 404
    end
  end

  test "show_simple_product" do
    get :show, :id => products(:recent).to_param
    assert_response :success
    assert_select 'p', products(:recent).description
    assert_select 'table', 0
  end

  test "should_not_show_unavailable_product" do
    get :show, :id => products(:future_title).to_param
    assert_redirected_to root_url
    assert_equal "Product not yet available.", flash[:error]
  end

  test "should_show_unavailable_simple_product_for_admin" do
    @user = login_as :admin
    get :show, :id => products(:future_title).to_param
    assert_response :success
    assert_match /^Available on /, flash[:notice]
  end

  test "show_product_with_sub_products" do
    session[:layout2] = 's'
    @product = Product.find(4)
    @product_format = @product.product_formats[0]
    assert @product.respond_to?(:titles)
    get :show, :id => @product.id
    assert_response :success
    assert_select 'p', @product.description
    assert_select 'div#subproducts', 1
    @product.titles.each do |p|
      assert_select 'table tr td', p.name
    end
  end
  
  test "add_to_cart" do
    assert_nil @user.cart
    assert_difference Cart, :count do
      assert_difference LineItem, :count do
        post :add, "items"=>{"1"=>{"quantity"=>"1", "id"=>"1"}}
        assert_redirected_to :action => "cart"
        assert_equal 'The selected items have been added to your cart.', flash[:notice]
      end
    end
  end
  
  test "update_cart" do
    Cart.expects(:find_by_token).once
    @cart = Cart.create(:user => @user)
    assert @cart
    @item = @cart.add_item(@product_format, 1)
    assert @item
    
    assert_no_difference LineItem, :count do
      post :update, 'items' => { @item.id => {:quantity => 2, :id => @product_format} }
      assert_redirected_to :action => "cart"
    end
    assert_equal 2, @item.reload.quantity
    assert_equal 2 * @product_format.price, @cart.reload.amount
    # assert_redirected_to :action => "cart"
    # assert_equal 'Your cart has been updated.', flash[:notice]
  end
  
  test "add_by_isbn" do
    assert_nil @user.cart
    assert_difference Cart, :count do
      assert_difference LineItem, :count do
        post :add_by_isbn, 'isbn' => @product.isbn
        assert_redirected_to :action => "cart"
        assert_equal "The selected items have been added to your cart.", flash[:notice]
      end
    end
  end
  
  test "fail_to_add_by_isbn" do
    @request.env["HTTP_REFERER"] = 'http://test.host/last/page/visited'
    assert_no_difference Cart, :count do
      assert_no_difference LineItem, :count do
        post :add_by_isbn, 'isbn' => 'bogus'
        assert_redirected_to @request.env["HTTP_REFERER"]
        assert_equal "No items added to your cart.", flash[:error]
      end
    end
  end
  
  test "find_cart_by_cookie" do
    login_as nil
    Cart.expects(:find_by_token).with(['foo']).once do
    @request.cookies['cart'] = CGI::Cookie.new("cart", 'foo')
    get :index
    assert_response :success
    end
  end
  
  test "find_cart_by_user" do
    @user = login_as :quentin
    assert_not_nil @user.cart
    get :index
    assert_response :success
    assert_equal @user.cart, assigns(:cart)
  end

  test "get_cart" do
    get :cart
    assert_response :success
  end

  test "should_not_search_products_when_query_empty" do
    post :search_results, :q => ''
    assert_template 'advanced_search'
    assert_equal "Please define at least one filter", flash[:error]
  end
  
  test "should_get_advanced_search_when_no_hits_for_quick_search" do
    post :search_results, :q => 'notexisting'
    assert_response :success
    assert_equal "No records found.", flash.now[:error]
    assert_template 'advanced_search'
  end

  test "should_search_products" do
    post :search_results, :q => 'old'
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should_search_products_using_search_results" do
    post :search_results, :name_contains => 'recent'
    assert_response :success
    assert_not_nil assigns(:products)
    assert_template 'search_results'
  end

  test "should_keep_using_advanced_search_when_no_hits" do
    post :search_results, :name_contains => 'notexisting', :commit => 'Submit'
    assert_response :success
    assert_template 'advanced_search'
    assert_equal "No records found.", flash.now[:error]
  end

  test "should_export_products" do
    get :export
    assert_response :success
    assert_not_nil assigns(:products)
    assert_template 'export'
  end

  test "should_export_cart" do
    # export cart
    get :export_cart
    assert_response :success
    assert_template 'export_cart'
  end

  test "get_quick_shop" do
    get :quick
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "get_new_titles" do
    get :new_titles
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "get_new_arrivals" do
    get :new_arrivals
    assert_response :success
    assert_not_nil assigns(:assemblies)
  end

  test "get_recent_arrivals" do
    get :recent_arrivals
    assert_response :success
    assert_not_nil assigns(:assemblies)
  end

  test "get_history" do
    get :history
    assert_response :success
    #assert_not_nil assigns(:products) # no history available, so nil TODO: 'make' history
  end

  test "should_add_to_cart_using_add_one" do
    @user = login_as :quentin
    assert_difference LineItem, :count do
      post :add_one, :id => products(:recent).default_format.id
      assert_redirected_to cart_path
      assert_equal "#{products(:recent).name} has been added to your cart.", flash[:notice]
    end
  end

  # refs #369 - deprecating test case; tested code is not for XHR, and it is not used in such way
#  test "should_add_to_cart_using_add_one_xhr" do
#    #@request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
#    @user = login_as :quentin
#    assert_difference LineItem, :count do
#      post :add_one, :id => products(:recent).default_format.id
#      assert_response :success
#      assert @response.body.include?('showCartMessage')
#      assert @response.body.include?('Element.update("cart_summary", ')
#    end
#  end

  test "add_one_should_handle_invalid_product_format_id" do
    assert_difference LineItem, :count, 0 do
      fakeid = ProductFormat.all.last.id + 1
      post :add_one, :id => fakeid
      assert_redirected_to cart_path
      assert_equal  "A product with the ID '#{fakeid}' could not be found.", flash[:error]
    end
  end
  test "should_verify_adding_and_removing_cart_items" do
    @user = login_as :quentin
    assert_difference LineItem, :count do
      post :add_one, :id => products(:recent).default_format.id
      assert_redirected_to cart_path
      assert_equal "#{products(:recent).name} has been added to your cart.", flash[:notice]
    end

    assert_difference LineItem, :count, -1 do
      put :remove_item, :id => @user.cart.line_items.reload.last.id
      assert_response :success
    end
  end

  test "should_destroy_cart" do
    @user = login_as :quentin # quentin has a cart
    assert_difference LineItem, :count, -(@user.cart.line_items.size) do
      get :destroy_cart
      assert_redirected_to cart_path
    end
  end

  test "should_save_cart_for_later_buy" do
    Cart.expects(:find_by_token).once
    # add an item to the cart
    assert_difference LineItem, :count do                      # expect 1 more line item
      post :add_one, :id => products(:recent).default_format.id
      assert_redirected_to cart_path
      assert_equal "#{products(:recent).name} has been added to your cart.", flash[:notice]
    end
    # store the item for later inspection
    line_item = @user.cart.reload.line_items.last
    assert_difference LineItem, :count, 0 do    # no line item should be deleted
      put :buy_later, :id => @user.cart.reload.line_items.last.id
      assert_response :success
      assert !@user.cart.reload.line_items.include?(line_item)  # but item should be gone from cart
      assert line_item.reload.saved_for_later                   # should be saved for later
    end
  end

  test "should_enlarge_cover" do
    post :enlarge, :id => products(:recent).to_param
    assert_response :success
  end

  test "should_enlarge_cover_js" do
    @request.accept = 'application/javascript'
    post :enlarge, :id => products(:recent).to_param
    assert_response :success
    assert_not_nil assigns(:product)
  end
  
  test "should_enlarge_spread_js" do
    @request.accept = 'application/javascript'
    post :enlarge, :id => products(:recent).to_param, :type => 'spreads'
    assert_response :success
    assert_not_nil assigns(:product)
  end

  test "should_check_coupon" do
    Cart.expects(:find_by_token).once
    @cart = Cart.create(:user => @user)
    assert @cart.add_item(@product_format, 1)
    discount = Discount.first
    post :coupon, :discount_code => discount.code
    assert_response :redirect
    assert_redirected_to cart_path
    assert_not_nil assigns(:cart)
    assert_equal "Your coupon code has been applied!", flash[:notice]
    assert_equal assigns(:cart).discount_code, discount.code
  end

  test "should_check_coupon_with_invalid_code" do
    Cart.expects(:find_by_token).once
    @cart = Cart.create(:user => @user)
    assert @cart
    @item = @cart.add_item(@product_format, 1)
    assert @item
    post :coupon, :discount_code => 'BADCODE'
    assert_response :redirect
    assert_redirected_to cart_path
    assert_not_nil assigns(:cart)
    assert_equal "Sorry, the coupon code 'BADCODE' is invalid.", flash[:error]

  end

  test "should_check_email_without_product" do
    get :email, :id => Product.last.id + 1
    assert_response :redirect
    assert_redirected_to root_path
    assert_equal "Product unknown.", flash[:notice]
  end

  test "should_check_email_get" do
    get :email, :id => products(:recent).to_param
    assert_response :success

  end

  test "should_check_email_post" do
    post :email, :id => products(:recent).to_param
    assert_response :success

  end

  test "should_check_email_post_with_valid_email" do
    post :email, :id => products(:recent).to_param, :form => { :email => 'test@milkfarmproductions.com', :message => 'Check Yo Self!' }
    assert_response :redirect
    assert_not_nil assigns(:product)
    assert_redirected_to show_path(assigns(:product))
    assert_equal "Your message was successfully delivered.", flash[:notice]
  end

  test "should_check_buy_now" do
    Cart.expects(:find_by_token).once
    @cart = Cart.create(:user => @user)
    assert @cart
    @item = @cart.add_item(@product_format, 1)
    assert @item
    @item.update_attributes(:saved_for_later => true)
    get :buy_now, :id => @item.to_param
    assert_response :success
  end

end
