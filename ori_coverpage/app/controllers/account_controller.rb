require 'lib/pdf_tool'
class AccountController < ApplicationController
  before_filter :admin_required, :only => [:reset]
  skip_before_filter :login_required, :only => [:login, :signup, :logout, :forgot_password]
  ssl_required :signup, :change_password
  include PdfTool
  
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
    @orders = current_user.orders.order('completed_at desc').limit(5)
  end

  def login
    # TODO: I think this is confusing. We have two different 'current_user' variable.
    # 1. from the User model using form params
    # 2. from method in lib/authenticated_system.rb
    @page_title = "Login"
    return unless request.post?
    self.current_user = User.authenticate(params[:email], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      init_user_cart
      redirect_back_or_default(root_path)
      flash[:notice] = "Logged in successfully"
    else
      flash[:error] = 'Invalid email and/or password'
    end
  end

  def signup
    @page_title = "Sign up"
    @user = Customer.new(params[:user])
    return unless request.post?
    if @user.save
      self.current_user = @user
      init_user_cart
      flash[:notice] = 'Thanks for signing up!'
      redirect_back_or_default(root_path)
    end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    destroy_cart
    reset_session
    flash[:notice] = "You have successfully logged out."
    redirect_back_or_default(root_path)
  end   
  
  def change_password
    @user = current_user
    return unless request.put?
    if params[:user] && params[:user][:password].blank?
      flash.now[:error] = 'Failed to update your password. Please complete the required fields.'
      render :action => 'change_password'
    elsif @user.update_attributes(params[:user])
      flash[:notice] = 'Your password was successfully updated.'
      redirect_back_or_default :action => 'index'
    else
      render :action => 'change_password'
    end
  end
  
  def change_profile
    @user = current_user
    return unless request.put?
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Your profile was successfully updated.'
      redirect_back_or_default :action => 'index'
    else
      flash[:notice] = "Profile not updated: \n#{@user.errors.full_messages}"
      render :action => 'change_profile'
    end
  end
  
  def forgot_password
    @page_title = 'Forgot Your Password?'
    # Always redirect if logged in
    if logged_in?
      flash[:notice] = 'You are currently logged in. You may change your password now.'
      redirect_to change_password_url
      return
    end
    return unless request.post?
    reset_password
  end
  
  def reset
    redirect_to forgot_password_url unless reset_password
  end
  
  def downloads
    @downloads = current_user.downloads.includes(:title).order("products.name").all
  end
  
  def download
    @download = current_user.downloads.find(params[:id])
    download_filename = @download.watermark_for_user(current_user)
    send_file(download_filename, :filename => "#{@download.title.sanitize_name.slice(0,30)}.pdf", :x_sendfile => CONFIG[:use_xsendfile])
  end
  
  def orders
    @page_title = 'Order History - Account'
    @orders = current_user.orders.order('completed_at desc').all
  end
  
  def order
    @page_title = 'Order Details - Account'
    @order = current_user.orders.find(params[:id])
  end
  
  def status_history
    @page_title = 'Order Status - Account'
    @order = current_user.orders.find(params[:id])
    @status_changes = @order.status_changes
  end
  
  def toggle_email_sale_status
    @user = current_user
    @user.preferred_email_sale_status = !@user.preferred_email_sale_status
    if @user.save
      flash[:notice] = 'Your email preferences were successfully updated.'
    else
      flash[:error] = 'Failed to updated your email preferences.'
    end
    redirect_to account_url
  end
  
  protected
  
    def reset_password
      if params[:email].blank?
        flash[:error] = 'Please enter a valid email address.'
      elsif (user = User.find_by_email(params[:email])).nil?
        flash[:error] = "We could not find a user with the email address #{params[:email]}"
      else
        new_password = generate_password()
        user.password = user.password_confirmation = new_password
        if user.save
          Rails.logger.debug("# DEBUG: SAVED!")
          NotificationMailer.forgot_password(user, new_password).deliver
          flash[:notice] = "Instructions on resetting your password have been emailed to #{params[:email]}"
          redirect_to login_url and return true
        else
          flash[:error] = "Your password could not be emailed to #{params[:email]}"
        end
      end
      false
    end
  
    def generate_password(length = 6)
      chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('1'..'9').to_a - ['o', 'O', 'i', 'I']
      Array.new(length) { chars[rand(chars.size)] }.join
    end
  
    # If there was a cart found via the cookie, and if that cart
    # is not the cart for the user who is logging in, move the items
    # to the cookie cart from the old cart if the cookie cart also has items.
    def init_user_cart
      @cart ||= init_cart
      if user_cart = current_user.cart
        if @cart != user_cart && !@cart.new_record?
          @cart.replaces(user_cart)
        else
          @cart = user_cart
        end
      elsif !@cart.new_record?
        @cart.update_attribute(:user, current_user)
      end
      set_cart_cookie
    end
end
