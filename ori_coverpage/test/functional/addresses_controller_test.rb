require File.dirname(__FILE__) + '/../test_helper'

class AddressesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  
  fixtures :addresses, :users, :postal_codes, :zones, :countries

  def setup
    @controller = AddressesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @address = Address.find(1)
    @user = login_as :admin
  end

  test "address_should_not_be_edited_by_another_user_than_owner" do
    @address = Address.find(2)
    assert_not_equal @address.addressable, @user
    get :edit, :id => @address.id
    assert_redirected_to addresses_url
    assert_equal 'Unauthorized.', flash[:error]
  end

  test "address_should_be_editable_by_owner_user" do
    assert_equal @address.addressable, @user
    get :edit, :id => @address.id
    assert_template 'edit'
  end

  test "address_should_be_editable_by_owner_user_in_checkout_context" do
    @user = login_as :quentin
    @address = @user.primary_address
    assert_not_nil @address
    assert_equal @address.addressable, @user
    get :edit, :context => 'checkout', :id => @address.id
    assert_template 'edit'
  end


  test "should_redirect_to_address_list_after_creation" do
    post :create, :address => @address.attributes,
      :postal_code => @address.postal_code.attributes
    assert_redirected_to addresses_url
  end

  test "should_redirect_to_checkout_after_creation_in_checkout_context" do
    post :create, :context => 'checkout', :address => @address.attributes,
      :postal_code => @address.postal_code.attributes
    assert_redirected_to checkout_shipping_url
  end

  test "should_redirect_to_checkout_billing_after_creation_in_checkout_context" do
    post :create, :context => 'checkout', :address => @address.attributes,
      :postal_code => @address.postal_code.attributes,
      :address_type => 'bill_address'
    assert_redirected_to checkout_billing_url
  end

  test "should_set_session_shipping_address_after_creation_in_checkout_context" do
    assert_difference Address, :count do
      post :create, :context => 'checkout', :address => @address.attributes,
        :postal_code => @address.postal_code.attributes
      assert_equal @request.session[:ship_address], Address.find(:last).id
    end
  end

  test "should_redirect_to_address_list_after_update" do
    post :update, :id => @address.id, :address => @address.attributes,
      :postal_code => @address.postal_code.attributes
    assert_redirected_to addresses_url
  end

  test "should_redirect_to_checkout_after_update_in_checkout_context" do
    post :update, :context => 'checkout', :id => @address.id, :address => @address.attributes,
      :postal_code => valid_postal_code
      #:postal_code => @address.postal_code.attributes
    assigns(:address).errors.each { |field,error| puts "#{field} #{error}" } # debug
    assigns(:postal_code).errors.each { |field,error| puts "#{field} #{error}" } # debug
    assert_redirected_to checkout_shipping_url
  end

  test "should_redirect_to_checkout_billing_after_update_in_context" do
    post :update, :context => 'checkout', :id => @address.id, :address => @address.attributes,
      :postal_code => @address.postal_code.attributes,
      :address_type => 'bill_address'
    assigns(:address).errors.each { |field,error| puts "#{field} #{error}" } # debug
    assigns(:postal_code).errors.each { |field,error| puts "#{field} #{error}" } # debug
    assert_redirected_to checkout_billing_url
  end

  test "should_set_session_billing_address_after_creation_in_context" do
    post :create, :context => 'checkout', :address => @address.attributes,
      :postal_code => @address.postal_code.attributes,
      :address_type => 'bill_address'
    assert_equal @request.session[:bill_address], Address.all.last.id
  end

  test "should_destroy_address" do
    @user = login_as :quentin
    assert_difference Address, :count, -1 do
      delete :destroy, :id => addresses(:quentin).to_param
      assert_redirected_to addresses_url
    end
  end

  test "should_not_allow_deletion_of_foreign_address" do
    @user = login_as :aaron
    @other_user = users(:quentin)
    # check that fixtures define addesses for @other_user
    assert !@other_user.addresses.nil?
    assert @other_user.addresses.count
    # attempt deletion
    assert_difference Address, :count, 0 do
      delete :destroy, :id => addresses(:quentin).to_param
      assert_redirected_to addresses_url
      assert_equal 'Unauthorized.', flash[:error]
    end
  end

  test "should_check_primary_toggling" do
    @user = login_as :quentin
    assert !@user.addresses.nil? && @user.addresses.count  # make sure @user has at least one address
    # add another address
    assert_difference Address, :count do
      post :create, :address => valid_address,
        :postal_code => @address.postal_code.attributes
      assert_redirected_to addresses_url
    end
    @old_primary = @user.primary_address
    assert !@old_primary.nil?
    # update primary address
    put :toggle_primary, :id => Address.all.last.id
    assert_redirected_to addresses_url
    assert_not_equal @old_primary, @user.primary_address
  end

  # this test case generates warnings that -- according to the debug i did -- can safely be ignored for now as warnings are generated by actionpack
  test "should_get_own_addresses" do
    @user = login_as :quentin
    assert !@user.addresses.nil? && @user.addresses.count  # make sure @user has at least one address
    get :index
    assert_response :success
    assert_not_nil assigns(:addresses)
    assert_equal @user.addresses, assigns(:addresses)
  end

  test "should_check_the_new_address_form" do
    @user = login_as :quentin
    get :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:address)
    assert_not_nil assigns(:postal_code)
    assert_equal 'New - Addresses', assigns(:page_title)
  end

  test "should_check_the_new_address_forms_in_checkout_context" do
    @user = login_as :quentin
    ["bill_address", "shipping_address"].each do |address_type|
      get :new, :context => 'checkout', :address_type => address_type
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:address)
      assert_not_nil assigns(:postal_code)
      @page_title = "New - #{(address_type == 'bill_address' ? 'billing' : 'shipping').titleize} Address - Checkout"
      assert_equal @page_title, assigns(:page_title)
    end
  end

  test "address_should_not_be_shown_to_another_user_than_owner" do
    @user = login_as :quentin
    @address = users(:admin).primary_address
    assert_not_equal @address.addressable, @user
    get :show, :id => @address
    assert_redirected_to addresses_url
    assert_equal 'Unauthorized.', flash[:error]
  end

  test "address_should_be_shown_to_owner_user" do
    @user = login_as :quentin
    @address = @user.primary_address
    assert_not_nil @address         # fixtures should define a primary address fpr user
    get :show, :id => @address
    assert_template 'show'
    assert_not_nil assigns(:address)
    assert_equal @address, assigns(:address)
  end

  test "should_check_creating_by_xml_api" do
    @user = login_as :quentin
    @request.accept = 'application/xml'

    assert_difference Address, :count do
      post :create, :address => valid_address,
        :postal_code => @address.postal_code.attributes
      assert_response :success
      assert_equal 'application/xml', @response.content_type
    end
  end

  test "should_not_create_invalid_address" do
    (invalid_address = valid_address)['country_id'] = nil
    @user = login_as :aaron
    assert_difference Address, :count, 0 do
      post :create, :address => invalid_address
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:address)
      #assigns(:address).errors.each { |field,error| puts "#{field} #{error}" } # debug
      assert assigns(:address).errors.collect { |field,error| "#{field} #{error}" }.include?("country_id can't be blank")
    end
  end

  test "should_not_update_address_with_invalid_attributes" do
    (invalid_address = valid_address)['country_id'] = nil
    @user = login_as :quentin
    assert_difference Address, :count, 0 do
      post :update, :id => @user.primary_address.id, :address => invalid_address
      assert_response :success
      assert_template 'edit'
      assert_not_nil assigns(:address)
      #assigns(:address).errors.each { |field,error| puts "#{field} #{error}" } # debug
      assert assigns(:address).errors.collect { |field,error| "#{field} #{error}" }.include?("country_id can't be blank")
    end
  end

  # test case hacks in the database in order to force execution to a branch that
  # should not execute under normal (normal application use) circumstances
  test "should_automatically_instantiate_new_postal_code_if_missing" do
    @user = login_as :quentin
    @address = @user.primary_address
    @old_postal_code = @address.postal_code

    # destroy the postal_code used by the address we want to update later on
    assert_difference PostalCode, :count, -1 do
      @old_postal_code.destroy
    end

    # let's update the address (that refers to an invalid /missing/ postal code)
    assert_difference Address, :count, 0 do
      # during the update, Address.load_postal code should enter the branch of generating a new postal code
      post :update, :id => @user.primary_address.id, :postal_code => valid_postal_code
      # should have reached 100% CC by now...
      assert_redirected_to addresses_url
      assert_equal 'Address was successfully updated.', flash[:notice]
    end
  end

end
