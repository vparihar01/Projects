require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users, :line_item_collections, :line_items, :products, :product_formats, :formats, :product_downloads

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @logger = ActiveRecord::Base.logger
  end

  test "should_fail_get_signup_form_over_non_ssl" do
    get :signup
    assert_response :redirect
  end

  test "should_get_signup_form_over_ssl" do
    @request.env['HTTPS'] = 'on'
    get :signup
    assert_response :success
    assert_template 'signup'
  end

  test "should_register_new_user" do
    assert_difference User, :count do
      @request.env['HTTPS'] = 'on'
      post :signup, :user => valid_user
      assert_not_nil assigns(:user)
      assert_redirected_to root_url
      assert_equal 'Thanks for signing up!', flash[:notice]
    end
  end

  test "should_not_register_invalid_user" do
    (invalid_user = valid_user)['name'] = ""
    assert_difference User, :count, 0 do
      @request.env['HTTPS'] = 'on'
      post :signup, :user => invalid_user
      assert_response :success
      assert assigns(:user).errors.collect { |field,error| "#{field} #{error}" }.include?("name can't be blank")
      assert_template 'signup'
    end
  end

  test "should_change_password" do
    @user = login_as :quentin
    @request.env['HTTPS'] = 'on'
    put :change_password, :id => @user.id, :user => { :password => 'changeme', :password_confirmation => 'changeme' }
    assert_redirected_to account_url
    assert_equal 'Your password was successfully updated.', flash[:notice]
  end

  test "should_return_to_change_password_on_password_mismatch" do
    @user = login_as :quentin
    @request.env['HTTPS'] = 'on'
    put :change_password, :id => @user.id, :user => { :password => 'changeme', :password_confirmation => 'CHANGEME' }
    assert_response :success
    assert_not_equal 'Your password was successfully updated.', flash[:notice]
    assert assigns(:user).errors.collect { |field,error| "#{field} #{error}" }.include?("password doesn't match confirmation")
  end

  test "should_login_and_redirect" do
    post :login, :email => 'quentin@example.com', :password => 'test'
    assert session[:user]
    assert_response :redirect
    assert_equal "Logged in successfully", flash[:notice]
  end

  test "should_fail_login_and_not_redirect" do
    post :login, :email => 'quentin@example.com', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
    assert_equal "Invalid email and/or password", flash[:error]
  end

  test "should_logout" do
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
    assert_equal "You have successfully logged out.", flash[:notice]
  end

  test "should_remember_me" do
    post :login, :email => 'quentin@example.com', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  test "should_not_remember_me" do
    post :login, :email => 'quentin@example.com', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  test "should_delete_token_on_logout" do
    post :login, :email => 'quentin@example.com', :password => 'test', :remember_me => "1"
    assert_not_equal @response.cookies["auth_token"], []
    assert_not_equal @response.cookies["auth_token"], nil
    get :logout
    assert_nil @response.cookies["auth_token"]
  end

  test "should_login_with_cookie" do
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert @controller.send(:logged_in?)
  end

  test "should_fail_cookie_login_with_invalid_token" do
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :index
    assert !@controller.send(:logged_in?)
  end

  test "change_profile_should_be_put" do
    @user = login_as :quentin
    post :change_profile, { :user => { :name => 'Quentin Tarantino'} }
    
    #assert_equal "Your profile was successfully updated.", flash[:notice]
    #assert_response :redirect
  end

  test "should_change_profile" do
    @user = login_as :quentin
    put :change_profile, { :user => { :name => 'Quentin Tarantino'} }
    
    assert_equal "Your profile was successfully updated.", flash[:notice]
    assert_response :redirect
    assert_redirected_to account_url
  end

  test "should_not_change_profile_with_error" do
    @user = login_as :quentin
    put :change_profile, { :user => { :name => ''} }
    assert_response :success
    assert_template 'change_profile'
    assert flash[:notice].include?("Profile not updated:")
    assert flash[:notice].include?("Name can't be blank")
  end

  test "should_request_password_change_when_logged_in" do
    @user = login_as :quentin
    get :forgot_password
    assert_response :redirect
    assert_redirected_to change_password_url
    assert_equal 'You are currently logged in. You may change your password now.', flash[:notice]
  end

  test "password_change_must_be_posted_when_not_logged_in" do
    get :forgot_password
    #assert_response :redirect
    #assert_redirected_to change_password_url
    #assert_equal 'You are currently logged in. You may change your password now.', flash[:notice]
  end

  test "should_handle_posted_password_change_when_not_logged_in" do
    assert_equal users(:quentin).crypted_password, users(:quentin).reload.crypted_password
    post :forgot_password, { :email => users(:quentin).email }
    assert_response :redirect
    assert_redirected_to login_url
    assert_equal "Instructions on resetting your password have been emailed to #{users(:quentin).email}", flash[:notice]
    assert_not_equal users(:quentin).crypted_password, users(:quentin).reload.crypted_password
  end

  test "should_fail_posted_password_change_with_a_blank_email" do
    post :forgot_password, { :email => '' }
    assert_response :success
    assert_equal 'Please enter a valid email address.', flash[:error]
  end

  test "should_fail_posted_password_change_with_invalid_email" do
    post :forgot_password, { :email => 'invalid email' }
    assert_response :success
    assert_equal "We could not find a user with the email address invalid email", flash[:error]
  end

  # TODO: try to exploit the error when email can not be sent upon password change (prevent user.save)

  test "get_user_downloads" do
    @user = login_as :quentin
    get :downloads
    assert_response :success
  end

  test "get_user_download" do
    # TODO prepare fixtures, pdf file, etc.; create paid order

    # first let's load the sale with a pdf
    @sale = line_item_collections(:paid_sale)
    assert_not_nil @sale, "There is no sale record!"

    # copy the test pdf to
    FileUtils.mkdir_p( Rails.root.to_s + "/protected/ebooks/0000/0001" )
    FileUtils.copy_file( Rails.root.to_s + "/test/fixtures/files/test.pdf", Rails.root.to_s + "/protected/ebooks/0000/0001/test.pdf" )

    # marking it as paid should trigger inserting a record into product_downloads_users
    @sale.mark_as_paid

    @user = login_as :mobile_schools
    # check that fixtures were prepared
    assert_not_nil @user.downloads.first, "User has no downloads"

    # do the actual download; watermarking occurs once the download is requested...
    get :download, :id => @user.downloads.first
    assert_response :success
    # inspect the results
    assert_equal 'binary', @response.header['Content-Transfer-Encoding']
    assert_equal "attachment; filename=\"#{@user.downloads.first.title.sanitize_name.slice(0,30)}.pdf\"", @response.header['Content-Disposition']
    # verify that the watermarked PDF is in place on the server
    tmpfilename = "#{@user.downloads.first.title.sanitize_name.slice(0,30)}_#{CONFIG[:pdftool_download_password].blank? ? "" : "sec_"}wm_#{@user.id}.pdf"
    assert_not_nil File.size( Rails.root.join(CONFIG[:pdftool_temp_dir]).join(tmpfilename) )

    # check the download size and the temp file size (must match) -> rails3: @response.header['Content-Length'] is not there anymore -- using @response.body.length
    assert_equal File.size( Rails.root.join(CONFIG[:pdftool_temp_dir]).join(tmpfilename) ), @response.body.length

    # TODO add more inspections on the header and body, make sure the file is streamed, etc.
    #assert_equal ...., @response.header['Content-Length']
    #puts @response.body
    #puts @response.header

    # clean up the temporary file(s)
    FileUtils.rm( Rails.root.to_s + "/protected/ebooks/0000/0001/test.pdf" )
    FileUtils.rm( Rails.root.join(CONFIG[:pdftool_temp_dir]).join(tmpfilename) ) # no support for wildcards
    #`rm -rf #{Rails.root.join("#{CONFIG[:pdftool_temp_dir]}")}/OldBook*.pdf` # deleting from console
  end

  test "get_user_orders" do
    @user = login_as :quentin
    get :orders
    assert_response :success
  end

  test "get_user_order" do
    @user = login_as :quentin
    get :order, :id => @user.orders.first
    assert_response :success
  end

  test "get_user_status_history" do
    @user = login_as :quentin
    get :status_history, :id => @user.orders.first
    assert_response :success
  end
  
  protected
    def auth_token(token)
      token       #CGI::Cookie.new('name' => 'auth_token', 'value' => token) # TODO check what has changed so this was neccessary; refs #390
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
