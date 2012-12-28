require File.dirname(__FILE__) + '/../test_helper'
require 'wishlists_controller'

# Re-raise errors caught by the controller.
class WishlistsController; def rescue_action(e) raise e end; end

class WishlistsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :specs, :addresses, :postal_codes, :zones, :countries,
           :line_item_collections, :line_items, :products, :product_formats

  def setup
    @controller = WishlistsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # TODO Replace this with your real tests.
  test "truth" do
    assert true
  end

  test "should_redirect_to_login_for_anonymous_when_accessing_wishlists" do
    @user = login_as :quentin
    @user = login_as nil
    get :index
    assert_redirected_to login_url
  end

  test "should_show_wishlist_for_known_user" do
    @user = login_as :quentin
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)
    get :index
    assert_response :success
    assert_not_nil assigns(:wishlist)
    assert_not_nil assigns(:line_items)
    assert_equal @wishlist, assigns(:wishlist)
  end

  test "should_destroy_wishlist" do
    @user = login_as :quentin
    @product = products(:recent)
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    assert_difference LineItemCollection, :count, -1 do
      delete :destroy, :id => @wishlist.id
    end

    assert_redirected_to :action => 'index'
    assert_not_nil assigns(:wishlist)
    assert_raise(ActiveRecord::RecordNotFound) { @wishlist.reload }
  end

  test "should_add_wishlist_item" do
    @user = login_as :quentin
    @product_format = product_formats(:one) # old.paper
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    assert_difference LineItem, :count do
      post :add, "wishlist_items" => { "#{@product_format.id}" => { :id => @product_format.id, :quantity => 1 } }
    end

    assert_redirected_to :action => 'index'
    assert_not_nil assigns(:wishlist)
    @wishlist.reload
    assert_equal @wishlist, assigns(:wishlist)
  end

  test "should_fail_adding_a_not_available_wishlist_item" do
    @user = login_as :quentin
    @product_format = product_formats(:future_title_paper)
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    post :add, "wishlist_items" => { "#{@product_format.id}" => { :id => @product_format.id, :quantity => 1 } }

    assert_redirected_to :action => 'index'
    assert_not_nil assigns(:wishlist)
    @wishlist.reload
    assert_equal @wishlist, assigns(:wishlist)
  end

  test "should_not_add_items_with_zero_quantity" do
    @user = login_as :quentin
    @product_format = product_formats(:one) # old_paper
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    @request.env['HTTP_REFERER'] = :wishlists

    assert_no_difference LineItem, :count do
      post :add, "wishlist_items" => { "#{@product_format.id}" => { :id => @product_format.id, :quantity => 0 } }
    end

    assert_redirected_to :action => 'index'
    assert_equal "No items were selected to add to your wishlist.", flash[:error]
  end

  test "should_update_wishlist" do
    assert true
    @user = login_as :quentin
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    @wishlist_updates = {}
    @wishlist.line_items.each { |item| @wishlist_updates["#{item.id}"] = { :id => item.id, :quantity => item.quantity * 2 } }
    post :update, :id => @wishlist.id, "items" => @wishlist_updates

    assert_equal "Your wishlist has been updated.", flash[:notice]
  end

  test "should_load_to_cart" do
    @user = login_as :quentin
    @wishlist = Wishlist.find_by_user_id(@user.id) || Wishlist.new(:user => @user)

    post :load_cart, :id => @wishlist.id

    assert_not_nil assigns(:cart)
    assert_redirected_to cart_path
  end

end
