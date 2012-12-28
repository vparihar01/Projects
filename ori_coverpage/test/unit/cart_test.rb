require File.dirname(__FILE__) + '/../test_helper'

class CartTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :line_item_collections, :line_items, :users, :products, :addresses, 
    :postal_codes, :zones, :countries, :discounts, :formats, :specs
  
  def setup
    @cart = Cart.find(1)
    @item = @cart.line_items.first
    # setup a non-free library processing scheme
    CONFIG[:reading_label_cost]      = 0.1
    CONFIG[:catalog_card_cost]       = 1
    CONFIG[:barcode_label_cost]      = 10
    CONFIG[:data_disk_cost]          = 100
    CONFIG[:data_disk_per_book_cost] = 0.15
    CONFIG[:free_library_processing] = false
  end
  
  test "add_product_to_new_cart_saves_cart" do
    @cart = Cart.new(:user => User.find(1))
    assert @cart.new_record?
    assert_difference Cart, :count do
      assert_difference LineItem, :count do
        assert @cart.add_item(Product.find(1).product_formats[0], 1)
        assert !@cart.new_record?
      end
    end
  end

  test "add_product_adds_a_new_line_item" do
    @cart = Cart.new(:user => User.find(1))
    assert_difference @cart.line_items, :count, 1, true do
      assert_difference LineItem, :count do
        assert @cart.add_item(Product.find(1).product_formats[0], 1)
      end
    end
  end

  test "should_not_allow_invalid_payment_method" do
    @cart = Cart.new(:user => User.find(1))
    assert_nil @cart.payment_method
    @cart.payment_method = 'blabla'
    assert_raise ActiveRecord::RecordInvalid do
      @cart.save!
    end
    assert_equal @cart.errors['payment_method'], ["is not included in the list"]
  end

  test "should_not_validate_payment_method_if_nil" do
    @cart = Cart.new(:user => User.find(1))
    assert_nil @cart.payment_method
    @cart.payment_method = nil
    @cart.save!
    assert @cart.errors.blank?
  end

  
  test "add_product_increments_existing_line_item" do
    assert_no_difference LineItem, :count do
      assert_difference LineItem.find(@item), :quantity, 1, true do
        @cart.add_item(@item.product_format, 1)
      end
    end
  end

  test "add_product_to_cart_updates_total" do
    @cart = Cart.new(:user => User.find(1))
    @product = Product.find(1)
    # add_item does not update total, only update_amount
    assert_no_difference @cart, :amount do
      assert @cart.add_item(@product.product_formats[0], 1)
    end
    # invoking update_amount
    assert_difference @cart, :amount, @product.product_formats[0].price do
      assert @cart.update_amount!
    end
  end
  
  test "change_item_quantity" do
    assert_no_difference LineItem, :count do
      assert_difference LineItem.find(@item), :quantity, 2, true do
         ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
        @cart.update_item(@item.id, @item.quantity + 2)
      end
    end
  end
  
  test "remove_line_item_with_zero_quantity" do
    assert_difference @cart.line_items, :count, -1 do
      assert_difference LineItem, :count, -1 do
        CardAuthorization.any_instance.expects(:destroy).once.returns(true)
        assert @cart.update_item(@item.id, 0)
      end
    end
  end
  
  test "deleting_a_cart_deletes_the_cart_items" do
    assert_difference Cart, :count, -1 do
      assert_difference LineItem, :count, -@cart.line_items.count do
        ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
        assert @cart.destroy
      end
    end
  end
  
  test "loading_quote_into_cart_clobbers_cart_line_items" do
    @quote = Quote.first
    assert (@quote_items = collect_items(@quote)).any?
    assert (@cart_items = collect_items(@cart)) != @quote_items
    @net_difference = @quote_items.size - @cart_items.size
    
    assert_difference LineItem, :count, @net_difference do
      ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
      assert @quote.copy_to_cart(@cart)
    end
    assert_equal @quote_items, collect_items(@cart)
  end
  
  test "loading_quote_into_cart_updates_cart_total" do
    @quote = Quote.first
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
    assert @quote.copy_to_cart(@cart)
    assert_equal @cart.amount, @cart.line_items.reload.collect(&:total_amount).sum
  end
  
  test "copy_from_cart_gets_cart_line_items" do
    create_cart
    assert @quote = Quote.create(valid_quote)
    assert @quote.copy_from_cart(@cart)
    assert_equal @cart.line_items.count, @quote.line_items.count
  end
  
  test "copy_from_cart_does_nothing_with_no_cart_items" do
    @cart = Cart.new
    assert @quote = Quote.create(valid_quote)
    assert @quote.copy_from_cart(@cart)
    assert_equal 0, @quote.line_items.count
  end
  
  test "replacing_old_cart_with_items_adds_items_to_new_cart" do
    @new_cart = Cart.create
    @new_cart.add_item(Product.find(2).product_formats[0])
    assert_equal [], @new_cart.line_items.collect(&:product_id) & @cart.line_items.collect(&:product_id)
    assert_equal 1, @new_cart.line_items.size
    assert_no_difference LineItem, :count do
      CardAuthorization.any_instance.expects(:destroy).once.returns(true)
      assert @new_cart.replaces(@cart)
    end
    assert_equal 2, @new_cart.reload.all_items.size
  end
  
  test "replacing_old_cart_with_items_does_not_add_overlapping_items_to_new_cart" do
    @new_cart = Cart.create
    @new_cart.add_item(Product.find(1).product_formats[0])
    @new_cart.add_item(Product.find(2).product_formats[0])
    assert_equal [1], @new_cart.line_items.collect(&:product_id) & @cart.line_items.collect(&:product_id)
    assert_equal 2, @new_cart.line_items.size
    assert_difference LineItem, :count, -1 do
      CardAuthorization.any_instance.expects(:destroy).once.returns(true)
      assert @new_cart.replaces(@cart)
    end
    assert_equal 2, @new_cart.reload.line_items.size
  end
  
  test "replacing_old_cart_destroys_old_cart" do
    @user = @cart.user
    @new_cart = Cart.create
    assert_difference Cart, :count, -1 do
      CardAuthorization.any_instance.expects(:destroy).once.returns(true)
      assert @new_cart.replaces(@cart)
    end
    assert_nil Cart.find_by_id(@cart.id)
  end
  
  test "replacing_old_cart_assigns_user_to_new_cart" do
    @user = @cart.user
    @new_cart = Cart.create
    assert_nil @new_cart.user
    CardAuthorization.any_instance.expects(:destroy).once.returns(true)
    assert @new_cart.replaces(@cart)
    assert_equal @user, @new_cart.reload.user
  end
  
  test "set_token" do
    @cart = Cart.new
    assert_nil @cart.token
    assert @cart.save
    assert_not_nil @cart.token
  end
  
  test "update_shipping_options_with_no_method" do
    @cart = Cart.new
    assert @cart.add_item(Product.find(1).product_formats[0], 1) # must be non-virtual product
    assert @cart.update_shipping!(ups_rate_list)
    assert_equal ups_rate_list.first.service_code, @cart.shipping_method
    assert_equal ups_rate_list.first.cost, @cart.shipping_amount
  end
  
  test "update_shipping_options_with_same_method" do
    @cart = Cart.new
    @cart.shipping_method = ups_rate_list.first.service_code
    @cart.shipping_amount = ups_rate_list.first.cost
    assert @cart.add_item(ProductFormat.first(:conditions => 'format_id=1')) # must be non-virtual product
    assert @cart.update_shipping!(ups_rate_list)
    assert_equal ups_rate_list.first.service_code, @cart.shipping_method
    assert_equal ups_rate_list.first.cost, @cart.shipping_amount
  end
  
  test "update_shipping_options_with_different_method" do
    @cart = Cart.new
    @cart.shipping_method = ups_rate_list.last.service_code
    @cart.shipping_amount = ups_rate_list.last.cost
    assert @cart.add_item(Product.find(1).product_formats[0], 1) # must be non-virtual product
    assert @cart.update_shipping!(ups_rate_list)
    assert_equal ups_rate_list.last.service_code, @cart.shipping_method
    assert_equal ups_rate_list.last.cost, @cart.shipping_amount
  end
  
  test "completing_a_sale" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
    pre_token = @cart.token
    assert_nil @cart.completed_at
    assert_equal 'Cart', @cart[:type]
    assert_difference Address, :count, 2 do
      assert @cart.complete_sale(@cart.user.addresses.first, @cart.user.addresses.first)
    end
    assert_not_equal @cart.token, pre_token
    assert_not_nil @cart.completed_at
    assert_equal 'Sale', @cart[:type]
  end
  
  test "completing_a_sale_should_add_the_products_to_the_user" do
    ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
    assert( (product_ids = @cart.line_items.collect(&:product_id)).size > 0 )
    assert @cart.complete_sale(@cart.user.addresses.first, @cart.user.addresses.first)
    assert_equal product_ids, @cart.user.product_ids
  end

  test "completing_a_sale_should_not_be_possible_if_user_id_is_nil" do
    #ActiveMerchant::Billing::BogusGateway.any_instance.expects(:void).once.returns(gateway_response)
    pre_token = @cart.token
    assert_nil @cart.completed_at
    assert_equal 'Cart', @cart[:type]
    @user = @cart.user    # save cart user for addresses
    assert_not_nil @user
    @cart.user_id = nil   # blank cart user id for fun
    assert @cart.save
    assert_nil @cart.user_id
    assert_raise ActiveRecord::RecordInvalid do   # complete sale should refuse to go on without user
      assert @cart.complete_sale(@user.addresses.first, @user.addresses.first)
    end
    @cart.reload
    assert_equal 'Cart', @cart[:type]
    assert_equal ["can't be blank"], @cart.errors[:user_id]
  end
 
  test "recalculating_the_total_with_no_change_should_not_unauthorize_the_cart" do
   @cart.update_amount!
   CardAuthorization.any_instance.expects(:destroy).never
   @cart.update_amount!
  end
  
  # TODO: why does ruby pass but rake fail???
  #   PASS: $ ruby test/unit/cart_test.rb
  #   FAIL: $ rake

  # test "recalculating_the_total_with_a_change_should_unauthorize_the_cart" do
  #   CardAuthorization.any_instance.expects(:destroy).once.returns(true)
  #   @cart.update_amount! # this should not unauthorize
  #   @cart.add_item(Product.find(2).product_formats[0], 1)
  #   @cart.update_amount! # this should unauthorize
  # end

  # test "authorizing_a_cart_should_destroy_previous_auth" do
  #   CardAuthorization.any_instance.expects(:destroy).twice.returns(true)
  #   @cart.card_authorization = CardAuthorization.new(valid_card(:user_id => @cart.user.id))
  #   @cart.authorize_payment(CardAuthorization.new(valid_card(:user_id => @cart.user.id, :first_name => 'Paul')), @cart.user.addresses.first)
  # end

  test "should apply a discount" do
    CardAuthorization.any_instance.expects(:destroy).once.returns(true)
    @cart.discount = Discount.find(1)
    assert_equal 0.1, @cart.discount.amount
    @address = @cart.user.addresses.first
    @cart.complete_sale(@address, @address)
    assert( @cart.amount > 0 )
    # no bundle is applied
    assert_equal 0, @cart.bundle_discount
    assert_equal @cart.amount / 10, @cart.discount_amount
  end

  # check non-free library processing
  test "should_check_out_processing_amount_free_by_config" do
    CONFIG[:free_library_processing] = true
    @cart = line_item_collections(:spectrum_cart)
    @spec = specs(:spectrum_specs)
    # make sure spec will request all non-free processing options
    assert @spec.include_readinglabels && @spec.include_kits && @spec.include_labels && @spec.include_disk
    assert @cart.line_items.count > 0
    assert @cart.user.is_a?(Customer)
    assert !%w(School Library).include?(@cart.user.category)  # we don't want any special discounting interfere that *may* apply to schools/libraries

    assert @cart.update_processing!(@spec)  # calculate processing_amount for a spec in current state (cart is not empty)
    assert @cart.reload

    assert_equal 0, @cart.processing_amount # should be free
  end

    # check non-free library processing
  test "should_check_out_processing_amount_free_by_no_specs" do
    CONFIG[:free_library_processing] = false
    @cart = line_item_collections(:spectrum_cart)
    @spec = specs(:spectrum_specs)
    # make sure spec will request all non-free processing options
    assert @spec.include_readinglabels && @spec.include_kits && @spec.include_labels && @spec.include_disk
    assert @cart.line_items.count > 0
    assert @cart.user.is_a?(Customer)
    assert !%w(School Library).include?(@cart.user.category)  # we don't want any special discounting interfere that *may* apply to schools/libraries

    assert @cart.update_processing!(nil)  # calculate processing_amount for a spec in current state (cart is not empty)
    assert @cart.reload

    assert_equal 0, @cart.processing_amount # should be free
  end


  # check non-free library processing
  test "should_check_out_processing_amount" do
    CONFIG[:free_library_processing] = false
    @cart = line_item_collections(:spectrum_cart)
    @spec = specs(:spectrum_specs)
    # make sure spec will request all non-free processing options
    assert @spec.include_readinglabels && @spec.include_kits && @spec.include_labels && @spec.include_disk
    assert @cart.line_items.count > 0
    assert @cart.user.is_a?(Customer)
    assert !%w(School Library).include?(@cart.user.category)  # we don't want any special discounting interfere that *may* apply to schools/libraries

    assert @cart.update_processing!(@spec)  # calculate processing_amount for a spec in current state (cart is not empty)
    assert @cart.reload
    assert @cart.processing_amount > 0 # assert it is nonzero

    per_book_price = (@spec.include_disk ? 1 : 0) * CONFIG[:data_disk_per_book_cost]
    physical_per_book_price = (@spec.include_readinglabels ? 1 : 0) * CONFIG[:reading_label_cost] + (@spec.include_kits ? 1 : 0) * CONFIG[:catalog_card_cost] + (@spec.include_labels ? 1 : 0) * CONFIG[:barcode_label_cost]
    processing_amount = @cart.processing_count * per_book_price + @cart.physical_processing_count * physical_per_book_price + (@spec.include_disk ? 1 : 0) * CONFIG[:data_disk_cost]
    assert_equal BigDecimal.new(processing_amount.to_s), @cart.processing_amount

    assert_difference @cart, :processing_amount, 0, true do # we should not see a difference in processing price change when removing a virtual item (not processed)
      # the difference should come from the virtual product still has title_count, remove it and check if the processing becomes equal for both calculations
      assert_difference LineItem, :count, -1 do
        assert @cart.line_items.find_by_product_format_id(product_formats(:old_book_pdf)).delete
      end
      assert @cart.update_processing!(@spec)
    end
  end

end
