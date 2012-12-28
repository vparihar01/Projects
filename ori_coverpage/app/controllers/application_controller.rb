# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Error404 < StandardError; end
class Error406 < StandardError; end
class PageNotFound < Error404; end
class ProductNotFound < Error404; end

class ApplicationController < ActionController::Base
  # clear_helpers                 # should fix issue #338
  include AuthenticatedSystem
  include SslRequirement
  include MiniCaptcha::ControllerHelpers

  helper_method :admin?, :admin_scope?, :checkout_scope?
  
  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery
  
  before_filter :fetch_singular_name
  before_filter :login_from_cookie
  before_filter :login_required
  before_filter :check_layout
  before_filter :admin_required_for_admin_paths

  before_filter :set_layout

  # Gracefully handle the following errors
  if CONFIG[:show_error_pages] == true
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from Error404, :with => :render_404
    rescue_from PageNotFound, :with => :render_page_not_found
    rescue_from ProductNotFound, :with => :render_product_not_found
    rescue_from Error406, :with => :render_406
    rescue_from ActionView::MissingTemplate, :with => :render_406
    rescue_from ActionController::InvalidAuthenticityToken, :with => :render_authenticity_token_error
  end
  
  def render_404
    respond_to do |type|
      type.html { render :template => "errors/error_404", :status => 404, :layout => 'error' }
      type.all  { render :nothing => true, :status => 404 }
    end
    true
  end
  
  def render_page_not_found
    respond_to do |type|
      type.html { render :template => "errors/page_not_found", :status => 404, :layout => 'error' }
      type.all  { render :nothing => true, :status => 404 }
    end
    true
  end
  
  def render_product_not_found
    respond_to do |type|
      type.html { render :template => "errors/product_not_found", :status => 404, :layout => 'error' }
      type.all  { render :nothing => true, :status => 404 }
    end
    true
  end
  
  def render_406
    render :template => "errors/error_406.html.erb", :status => 406, :layout => 'error'
    true
  end
  
  def render_authenticity_token_error
    logger.warn "INVALID AUTHENTICITY TOKEN!!!"
    respond_to do |type|
      type.html { render :template => "errors/authenticity_token_error", :status => 404, :layout => 'error' }
      type.all  { render :nothing => true, :status => 404 }
    end
    true
  end
  
  def allow_only_html_requests
    raise Error406 if params[:format] && params[:format] != "html"
  end
  
  def create
    @obj = self.instance_variable_get('@' + @name)
    if @obj.save
      flash[:notice] = "The #{@name.humanize.downcase} has been created."
      redirect_back_or_default :action => 'index'
    else
      render :action => 'new'
    end
  end

  def update
    @obj = self.instance_variable_get('@' + @name)
    if @obj.update_attributes(params[@name.to_sym])
      flash[:notice] = "The #{@name.humanize.downcase} has been updated."
      redirect_back_or_default :action => 'show', :id => @obj
    else
      render :action => 'edit'
    end
  end
  
  protected
    
    def fetch_singular_name
      @name = controller_name.singularize
    end
    
    def pager
      session[:layout] == 's' ? CONFIG[:compact_per_page] : CONFIG[:extended_per_page]
    end
    
    def init_cart
      return @cart if @cart
      
      if cookies[:cart]
        @cart = Cart.find_by_token(cookies[:cart])
      elsif logged_in?
        @cart = current_user.cart
      end
      
      @cart ||= Cart.new(:user => (logged_in? ? current_user : nil))
    end
    
    def clean_cart
      @cart.save_for_later_inactive_line_items! if @cart
    end
    
    def set_cart_cookie
      if @cart
        @cart.update_attribute(:user, current_user) if logged_in? && !@cart.user
        cookies[:cart] = { :value => @cart.token, :expires => 1.year.from_now }
      else
        destroy_cart
      end
    end
    
    def destroy_cart
      cookies[:cart] = { :value => nil, :expires => 1.day.ago }
    end

    def check_layout
      # layout, shared/view control layout pref for list pages
      session[:layout] ||= 'x'
      session[:layout] = params[:l] unless params[:l].blank?
      # layout2, shared/view2 control layout pref for show pages
      session[:layout2] ||= 'x'
      session[:layout2] = params[:l2] unless params[:l2].blank?
    end
    
    # This filter only allows access if the user is an admin
    def admin_required
      unless admin?
        render_page_not_found and return
      end
    end
    
    def admin_scope?
      request.path =~ /admin/
    end
    
    def admin_required_for_admin_paths
      admin_required if admin_scope?
    end
    
    def checkout_scope?
      params[:context] == 'checkout'
      # request.path =~ /checkout/
    end
    
    def admin?
      logged_in? && current_user.admin?
    end

    # this sets the layout from CONFIG[:controller_layouts]['some_controller'], if defined
    # should be triggered as a :before_filter hook...
    # if no such configuration option is defined, the layout will default to the one defined in the code
    def set_layout
      if layout = CONFIG[:controller_layouts][self.class.to_s.underscore]
        self.class.layout layout
      end
    end

    def verify_date_params
      if !params[:start_date].blank? && !/\d\d\d\d-\d\d-\d\d/.match(params[:start_date])
        flash.now[:error] = "Start date must be formatted as YYYY-MM-DD."
        return false
      elsif !params[:end_date].blank? && !/\d\d\d\d-\d\d-\d\d/.match(params[:end_date])
        flash.now[:error] = "End date must be formatted as YYYY-MM-DD."
        return false
      else
        return true
      end
    end
    
end
