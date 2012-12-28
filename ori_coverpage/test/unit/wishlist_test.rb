require File.dirname(__FILE__) + '/../test_helper'

class WishlistTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :line_items, :users, :products
  
  def setup
    @wishlist = Wishlist.first
    @item = @wishlist.line_items.first
  end
  
  test "add_product_to_new_wishlist_saves_wishlist" do
    @wishlist = Wishlist.new(:user => User.find(1))
    assert @wishlist.new_record?
    assert_difference Wishlist, :count do
      assert_difference LineItem, :count do
        assert @wishlist.add_item(Product.find(1).product_formats[0], 1)
        assert !@wishlist.new_record?
      end
    end
  end
  
  test "add_product_adds_a_new_line_item" do
    @wishlist = Wishlist.new(:user => User.find(1))
    assert_difference @wishlist.line_items, :count, 1, true do
      assert_difference LineItem, :count do
        assert @wishlist.add_item(Product.find(1).product_formats[0], 1)
      end
    end
  end
  
  test "add_wishlist_to_cart" do
    @cart = Cart.first
    assert_not_equal collect_items(@wishlist), collect_items(@cart)
    assert_difference LineItem, :count, @wishlist.line_items.size  do
      CardAuthorization.any_instance.expects(:destroy).once.returns(true)
      assert @wishlist.copy_to_cart(@cart, false)
      # assert_equal collect_items(@wishlist), collect_items(@cart)
    end
  end
  
  test "replace_cart_with_wishlist" do
    @cart = Cart.first
    assert_not_equal collect_items(@wishlist), collect_items(@cart)
    CardAuthorization.any_instance.expects(:destroy).once.returns(true)
    assert @wishlist.copy_to_cart(@cart, true)
    assert_equal collect_items(@wishlist), collect_items(@cart)
  end
  
end