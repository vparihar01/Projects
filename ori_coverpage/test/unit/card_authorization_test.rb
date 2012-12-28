require File.dirname(__FILE__) + '/../test_helper'

class CardAuthorizationTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :line_items, :products, :product_formats, :users, :addresses, :discounts, :bundles_products
  
  def setup
    @cart = Cart.find(1)
    assert_not_nil @cart
  end
  
  test "should_get_cart_attributes" do
    @auth = CardAuthorization.new(:cart => @cart)
    { :line_item_collection_id => :id, :user => :user, :amount => :total_amount }.each do |a,c|
      assert_equal @auth.send(a), @cart.send(c)
    end
  end
  
  test "should_return_an_Active_Merchant_credit_card" do
    @auth = CardAuthorization.new(valid_card)
    @cc = @auth.creditcard
    assert_equal @cc.class, ActiveMerchant::Billing::CreditCard
    assert_equal @cc.valid?, true
    assert_equal @cc.number, valid_card[:number]
  end
  
  test "should_validate_card_when_created" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:authorize).once.returns(gateway_response)
    ActiveMerchant::Billing::CreditCard.any_instance.expects(:valid?).once.returns(true)
    assert_difference CardAuthorization,:count, 1 do
      @auth = CardAuthorization.create(valid_card(:cart => @cart))
    end
  end

  test "should_run_authorization_when_created" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:authorize).once.returns(gateway_response)
    assert_difference CardAuthorization, :count, 1 do
      @auth = CardAuthorization.create(valid_card(:cart => @cart))
    end
  end
  
  test "should_void_authorization_when_destroyed" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:authorize).once.returns(gateway_response)
    ActiveMerchant::Billing::CreditCard.any_instance.expects(:valid?).once.returns(true)
    assert_difference CardAuthorization, :count, 0 do
      @auth = CardAuthorization.create(valid_card(:cart => @cart))
      ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
      @auth.destroy
    end
  end
  
  test "should_truncate_the_card_number" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:authorize).once.returns(gateway_response)
    @auth = CardAuthorization.create(valid_card(:cart => @cart))
    assert_equal @auth.number, 'bogus'
  end

  test "should_not_run_authorization_when_created_with_bad_data" do
    # let's use a cart that had no authorization in fixtures
    @cart = Cart.find(9)    # line_item_collections(:cart_without_card_authorization)
    assert_not_nil @cart
    # we should have no new card authorization if omitting essential data
    assert_difference CardAuthorization, :count, 0 do
      @cart.user_id = nil              # mess up cart data, remove user_id
      @cart.save(:validate => false)
      # pass cart without user_id for authorization
      @auth = CardAuthorization.create(valid_card(:cart => @cart))
      assert_not_nil @auth        # we should have a CA instance
      assert @auth.new_record?    # that should be dirty
      assert !@auth.errors.blank? # with errors
      assert @auth.errors.full_messages.join(";; ").include?("something went wrong.") # including the specific error to failing without even trying to auth
      assert @auth.errors.full_messages.join(";; ").include?("contact webmaster") # including the specific error to failing without even trying to auth
    end
  end

end
