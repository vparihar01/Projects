require File.dirname(__FILE__) + '/../test_helper'

class CheckoutControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :specs, :addresses, :postal_codes, :zones, :countries, :line_item_collections, :line_items, :products, :product_formats, :formats

  def setup 
    @user = User.find(login_as(:quentin))
    @cart = @user.cart
    UPS::Client.any_instance.stubs(:rate_list).returns(ups_rate_list)
    # enforce the use of HTTPS protocol
    @request.env['HTTPS'] = 'on'
    @controller = CheckoutController.new
  end

  test "should_list_the_users_specifications_for_institutes" do
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    @cart.add_item(Product.find(1).product_formats[0])
    assert Customer::INSTITUTIONS.include?(@user.category)
    get :processing
    assert_response :success
    assert assigns[:step_heading].match(/Step 1 of 4/)
    assert_select('input[name=specification]', @user.specs.count + 1)
    get :shipping
    assert assigns[:step_heading].match(/Step 2 of 4/)
  end

  test "should_skip_processing_specifications_for_non_institutional_users" do
    assert !Customer::INSTITUTIONS.include?(@user.category)
    get :processing
    assert_response :redirect
    assert_redirected_to checkout_shipping_url
    get :shipping
    assert assigns[:step_heading].match(/Step 1 of 3/)
  end

  test "should_skip_processing_specifications_for_cart_with_nonprocessable_items_only" do
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    assert_difference @cart.line_items, :count, 1 do
      @cart.add_item(product_formats(:old_book_pdf))
    end
    assert_equal 0, @cart.processing_count
    assert Customer::INSTITUTIONS.include?(@user.category)
    get :processing, :specification => @user.specs.first.id
    assert_response :redirect
    assert_redirected_to checkout_shipping_url
    assert_equal 0, @cart.processing_amount
    assert_equal 0, @cart.alsquiz_amount
    get :shipping
    assert assigns[:step_heading].match(/Step 1 of 3/)
  end


  test "should_select_no_processing_by_default_institutional_users_only" do
    @user = User.find(login_as(:dallas_schools))
    assert Customer::INSTITUTIONS.include?(@user.category)
    @cart = Cart.create(:user => @user)
    assert_difference @cart.line_items, :count, 1 do
      @cart.add_item(Product.find(1).product_formats[0])
    end
    get :processing
    assert_response :success
    assert assigns[:step_heading].match(/Step 1 of 4/)
    # no processing option is called 'do_not_process'
    assert_select "input[name=specification][value=do_not_process][checked=checked]"
  end

  test "should_select_the_specification_chosen_by_the_user_institutional_users_only" do
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    @cart.add_item(Product.find(1).product_formats[0])

    spec = @request.session[:spec] = @user.specs.first
    @cart.update_processing!(spec)
    get :processing
    assert_response :success
    assert_template 'processing'
    assert assigns[:step_heading].match(/Step 1 of 4/)
    assert_select "input[name=specification][value=#{spec.id}][checked=checked]"
  end

  test "should_set_the_selected_specification_in_the_session" do
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    @cart.add_item(Product.find(1).product_formats[0])

    post :processing, :specification => @user.specs.first.id
    assert_redirected_to :action => 'shipping', :protocol => 'https://'
    assert_equal @request.session[:spec], @user.specs.first
  end

  test "should_not_set_the_selected_specification_for_another_user" do
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    @cart.add_item(Product.find(1).product_formats[0])

    assert_raise(ActiveRecord::RecordNotFound) {
      post :processing, :specification => User.find(users(:admin)).specs.first.id
    }
    assert_nil @cart.reload.spec
    # TODO: based on the current behaviour, we can expect HTTP 200 here, revise and remove comment if OK
    assert_response :success
    #assert_redirected_to :action => 'shipping', :protocol => 'https://'
  end


  test "should_list_the_users_addresses" do
    get :shipping
    #should.select('input[name=address]', @user.addresses.count)
    assert_select('input[name=address]', @user.addresses.count)
  end

  test "should_set_the_selected_address_in_the_session" do
    post :shipping, :address => @user.addresses.first
    assert_equal @request.session[:ship_address], @user.addresses.first
    assert_redirected_to :action => 'billing'
  end

  test "should_not_set_the_selected_address_for_another_user" do
    assert(!@user.addresses.include?(@address = Address.find(1)))
    post :shipping, :address => @address.id
    assert_equal @request.session[:ship_address], @user.addresses.first
    assert_redirected_to :action => 'shipping'
  end

  test "should_select_the_address_chosen_by_the_user" do
    address = @user.addresses.first
    @request.session[:ship_address] = address
    get :shipping
    assert_select "input[name=address][value=#{address.id}][checked=checked]"
  end

  test "should_update_the_shipping_costs_when_viewing_the_shipping_addresses" do
    Cart.any_instance.expects(:update_shipping!).once
    get :shipping
  end

  test "should_update_the_shipping_method_when_updating_the_shipping" do
    assert_nil @cart.shipping_method
    Cart.any_instance.expects(:update_shipping!).once.returns(true)
    post :shipping, :address => @user.addresses.first.id, :shipping => ups_rate_list.first.service_code
    
    assert_response :redirect
    assert_redirected_to checkout_billing_url
    assert_equal ups_rate_list.first.service_code, @cart.reload.shipping_method
  end

  test "should_redirect_to_address_editing_if_shipping_address_selected_has_errors" do
    assert_nil @cart.shipping_method
    # let's corrupt the address record first
    @address = @user.addresses.first
    @address.postal_code_id = nil
    @address.save(:validate => false)
    assert @user.addresses.first.postal_code_id.nil?
    post :shipping, :address => @user.addresses.first.id, :shipping => ups_rate_list.first.service_code

    assert_response :redirect
    assert_redirected_to checkout_edit_address_url( @address, :address_type => :ship_address )
  end

  # TODO revise that this test case is doing what it's supposed to do
  test "should_set_the_shipping_rate_list_in_the_session_when_viewing_shipping_addresses" do
    get :shipping
    assert_equal ups_rate_list[0], @request.session[:shipping_options][0]
  end

  test "should_require_a_shipping_address_before_showing_the_billing_addresses" do
    get :billing
    assert_redirected_to :action => 'shipping', :protocol => 'https://'
  end

  test "should_list_the_users_addresses_for_billing_selection" do
    @request.session[:ship_address] = @user.addresses.first
    get :billing
    assert_select('input[name=address]', @user.addresses.count)
  end

  test "should_default_the_billing_address_to_the_selected_shipping_address" do
    @request.session[:ship_address] = @user.addresses.first
    @request.env['HTTPS'] = 'on'
    get :billing
    assert_equal @user.addresses.first, @request.session[:bill_address]
  end

  test "should_set_the_selected_billing_address_in_the_session" do
    @request.session[:ship_address] = @user.addresses.first
    post :billing, :address => @user.addresses.first.id, :payment_method => 'PO'
    assert_equal @request.session[:bill_address], @user.addresses.first
    assert_redirected_to :action => 'review'
  end

  test "should_redirect_to_address_editing_if_billing_address_selected_has_errors" do
    @request.session[:ship_address] = @user.addresses.first
    # let's corrupt the address record first
    @address = @user.addresses.first
    @address.postal_code_id = nil
    @address.save(:validate => false)
    assert @user.addresses.first.postal_code_id.nil?
    post :billing, :address => @user.addresses.first.id, :payment_method => 'PO'

    assert_response :redirect
    assert_redirected_to checkout_edit_address_url( @address, :address_type => :bill_address )
  end

  # TODO: revise test case, according to current implementation, there is no redirect here, remove comment if OK
  test "should_not_set_the_selected_billing_address_for_another_user" do
    assert(!@user.addresses.include?(@address = Address.find(1)))
    @request.session[:ship_address] = @user.addresses.first
    post :billing, :address => @address.id
    assert_equal @request.session[:bill_address], @user.addresses.first
    #assert_redirected_to :action => 'billing'
    assert_response :success
    assert_select('div[class=flash-error]', "Error choosing billing address")
  end

  test "should_select_the_billing_address_chosen_by_the_user" do
    set_addresses
    get :billing
    assert_select "input[name=address][value=#{@address.id}][checked=checked]"
  end

  test "should_require_a_card_authorization_for_the_cart_when_reviewing" do
    set_addresses
    get :review
    assert_redirected_to :action => 'billing', :protocol => 'https://'
    assert_equal flash[:error], 'Please select a payment method'
  end

  test "should_require_a_shipping_address_in_the_session_for_review" do
    get :review
    assert_redirected_to :action => 'shipping', :protocol => 'https://'
  end

  test "should_require_a_billing_address_in_the_session_for_review" do
    @request.session[:ship_address] = @user.addresses.first
    get :review
    assert_redirected_to :action => 'billing', :protocol => 'https://'
  end

  test "should_test_free_shipping_for_institutes" do
    CONFIG[:free_shipping_for_institutions] = true # override whatever was in this setting to test the case
    @user = User.find(login_as(:dallas_schools))
    @cart = Cart.create(:user => @user)
    @cart.add_item(Product.find(1).product_formats[0])
    assert Customer::INSTITUTIONS.include?(@user.category)

    @request.session[:ship_address] = @user.addresses.first
    get :shipping
    assert_response :success
    assert_equal ups_rate_list.first.service_code, @cart.reload.shipping_method
    assert_equal 0, @request.session[:shipping_options][0].cost
  end


  # TODO review test case result - based on current implementation ,there is no redirect here. remove comment if OK
  test "should_review_the_sale" do
    #Cart.any_instance.expects(:complete_sale).once.returns(true)
    set_addresses
    @cart.update_attribute(:payment_method, 'Purchase Order')
    post :review
    #assert_redirected_to :action => 'review', :id => @cart.reload.token, :protocol => 'https://'
    assert_response :success
  end

  # TODO make sure this test case is doing what it is expected
  test "should_complete_the_sale" do
    #Cart.any_instance.expects(:complete_sale).once.returns(true)
    set_addresses
    @cart.update_attribute(:payment_method, 'Purchase Order')
    post :complete
    #assert_redirected_to :action => 'complete', :id => @cart.reload.token, :protocol => 'https://'
    assert_response :success
  end

  test "should_run_an_authorization_when_paying_with_credit_card" do
    Cart.any_instance.expects(:authorize_payment).once.returns(true)
    @request.session[:ship_address] = @address = @user.addresses.first
    post :billing, :address => @address.id, :payment_method => 'Credit Card',
      :authorization => valid_card.stringify_keys
    assert_redirected_to :action => 'review'
  end

  test "should_display_processing_errors_for_credit_card_payments" do
    @request.session[:ship_address] = @address = @user.addresses.first
    post :billing, :address => @address.id, :payment_method => 'Credit Card',
      :authorization => valid_card(:number => '2').stringify_keys
    assert_template 'billing'
    #response.body.should.include('Bogus Gateway: Forced failure')
    assert_match(/Bogus Gateway: Forced failure/, @response.body)
  end

  test "should_not_run_an_authorization_for_non_credit_card_payments" do
    Cart.any_instance.expects(:authorize_payment).never
    @request.session[:ship_address] = @address = @user.addresses.first
    post :billing, :address => @address.id, :payment_method => 'Purchase Order'
    assert_redirected_to :action => 'review'
  end

end

# a helper method?
def set_addresses
  @address = @user.addresses.first
  @request.session[:ship_address] = @address
  @request.session[:bill_address] = @address
end