class CheckoutController < ApplicationController
  before_filter :init_cart
  before_filter :check_cart, :except => :complete
  before_filter :check_shipping, :only => [:billing, :review]
  before_filter :check_billing, :only => :review
  before_filter :check_authorization, :only => :review
  # after_filter :set_step_heading, :only => [:processing, :shipping, :billing, :review]
  ssl_required :processing, :shipping, :billing, :review, :complete

  def processing
    unless Customer::INSTITUTIONS.include?(current_user.category) && @cart && @cart.processing_count > 0
      Rails.logger.debug { "# DEBUG: Not an Institution -- Skip processing" } unless Customer::INSTITUTIONS.include?(current_user.category)
      Rails.logger.debug { "# DEBUG: No processable items -- Skip processing" } unless @cart && @cart.processing_count > 0
      session[:spec] = nil
      set_cart_processing # TODO: refs #300 :: make sure under no circumstances this will add extra costs for nonprocessable carts
      redirect_to checkout_shipping_url and return
    end
    set_step_heading(1)
    return unless request.post?
    if params[:specification] == 'do_not_process' || session[:spec] = current_user.specs.find(params[:specification])
      session[:spec] = nil if params[:specification] == 'do_not_process'
      set_cart_processing
      redirect_to checkout_shipping_url
    else
      session[:spec] = nil
      flash[:error] = "Error choosing specification"
      # redirect_to checkout_processing_url
    end
  end
  
  def shipping
    set_step_heading(2)
    if request.post?
      session[:ship_address] = current_user.addresses.find(params[:address])
      # make sure the address is valid
      if session[:ship_address] && session[:ship_address].valid?
        @cart.shipping_method = params[:shipping]
        @cart.save
        redirect_to checkout_billing_url    # proceed to billing if all ok
      else                          # redirect to editing the invalid address if not ok
        flash[:error] = "The Shipping Address has errors. Please fix before proceeding: #{session[:ship_address].errors.full_messages.join("; ")}"
        redirect_to checkout_edit_address_url(params[:address], :address_type => :ship_address) and return
      end
    else
      session[:ship_address] ||= current_user.primary_address
    end
    
    fetch_rate_list
    set_cart_shipping

  rescue ActiveRecord::RecordNotFound
    session[:ship_address] = current_user.primary_address
    flash[:error] = "Error choosing shipping address"
    redirect_to checkout_shipping_url
  end
  
  def billing
    set_step_heading(3)
    if request.post?
      session[:bill_address] = current_user.addresses.find(params[:address])
      # validate the billing address, only proceed if address validates
      if session[:bill_address] && session[:bill_address].valid?
        @cart.update_attributes(:payment_method => params[:payment_method], :comments => params[:comments])
        @authorization = CardAuthorization.new(params[:authorization])

        if params[:payment_method].blank?
          flash.now[:error] = "Please select a payment method"
        elsif params[:payment_method] == 'Credit Card' && !@cart.authorize_payment(@authorization, session[:bill_address], session[:spec])
          flash.now[:error] = "Credit card authorization failed"
        else
          @cart.apply_taxes(session[:bill_address], session[:spec])
          redirect_to checkout_review_url
        end
      else  # if billing address does not validate, redirect to editing it
        flash[:error] = "The Billing Address has errors. Please fix before proceeding: #{session[:bill_address].errors.full_messages.join("; ")}"
        redirect_to checkout_edit_address_url(params[:address], :address_type => :bill_address) and return
      end
    else
      session[:bill_address] ||= session[:ship_address]
    end
    #TODO add tax calculations here #118
    
  rescue ActiveRecord::RecordNotFound
    session[:bill_address] = session[:ship_address]
    flash.now[:error] = "Error choosing billing address"
  end
  
  def review
    set_step_heading(4)
    # TODO: this causes the card authorization to be voided then destroyed
    # @cart.update_alsquiz!(session[:spec]) # also done before authorize_payment
    
    # if request.post?
    #   @cart.complete_sale(session[:ship_address], session[:bill_address], session[:spec])
    #   destroy_cart
    #   redirect_to checkout_complete_url(:id => @cart.token) and return
    # end
  end
  
  def complete
    @cart.complete_sale(session[:ship_address], session[:bill_address], session[:spec])
    if @sale = Sale.find_by_token(@cart.token)
      destroy_cart
      NotificationMailer.order(current_user, @sale).deliver
    else
      flash[:error] = "Sale not found. Please contact the webmaster."
      redirect_to '/' and return false
    end
  end
  
  def calc_shipping
    render :nothing => true and return false unless @address = current_user.addresses.find(params[:address_id])
    fetch_rate_list(@address)
    render :update do |page|
      page.replace_html 'shipping_options', :partial => 'shipping_option', :collection => session[:shipping_options]
    end
  rescue UPS::UPSError => @error
    render :update do |page|
      page.alert @error.message
    end
  end
  
  protected
  
    def set_cart_shipping
      @cart.update_shipping!(session[:shipping_options])
    end 
    
    def set_cart_processing
      @cart.update_alsquiz!(session[:spec])
      @cart.update_processing!(session[:spec])
    end
    
    def fetch_rate_list(address = session[:ship_address])
      #TODO review the following commented lines and erase them if no need anymore
      #return unless address
      #session[:shipping_options] = Rails.env.development? ? 
      #  [ OpenStruct.new(:service_code => '03', :label => 'UPS Ground', :cost => 0) ] :
      #  ups_client.rate_list(address, @cart.weight, shipping_cost_overrides)  

      shipcost = 0
      if CONFIG[:free_shipping_for_institutions] == true && Customer::INSTITUTIONS.include?(current_user.category)
        shipcost = 0
      else
        case CONFIG[:shipping_costs_method]
          # TODO revise if cherrylake & childsworld calculations really need to differ
          # TODO implement weight-based shipping calculations
          # TODO implement item-number based calculations?
          # TODO remove obsolete comments
        when "percentage1", nil   # cherrylake-like
          #session[:shipping_options] = [ OpenStruct.new(:service_code => '03', :label => 'UPS Ground', :cost => (0.075 * @cart.amount)) ]
          shipcost = CONFIG[:shipping_cost_factor] * @cart.amount
        when "percentage2"        # childsworld-like (deals with saved-later items, etc.)
          #session[:shipping_options] = [ OpenStruct.new(:service_code => '03', :label => 'UPS Ground', :cost => shipcost, :description => '10% of the total of Paper copies or $5.00, whichever is greater' ) ]
          shipcost = CONFIG[:shipping_cost_factor] * @cart.shipping_base_amount
        end
        # Check minimum
        if CONFIG[:shipping_min_cost] > 0 && shipcost < CONFIG[:shipping_min_cost]
          shipcost = CONFIG[:shipping_min_cost]
        end
        # Check maximum
        if CONFIG[:shipping_max_cost] > 0 && shipcost > CONFIG[:shipping_max_cost]
          shipcost = CONFIG[:shipping_max_cost]
        end
      end
      # Set option
      session[:shipping_options] = [ OpenStruct.new(:service_code => '03', :label => 'UPS Ground', :cost => shipcost, :description => CONFIG[:shipping_description_ups]) ]
    end

    def ups_client
      @ups_client ||= UPS::Client.new(
        YAML.load_file(Rails.root.join('config', 'ups.yml'))
        )
    end
    
    def shipping_cost_overrides
      # Make UPS Ground shipping free
      { '03' => 0 }
    end 
    
    def check_cart
      if @cart.line_items.count == 0
        flash[:error] = "Please add items to your cart before attempting to checkout"
        redirect_to cart_url and return false  
      end 
    end
  
    def check_shipping
      redirect_to checkout_shipping_url and return false unless session[:ship_address] && session[:ship_address].valid?
    end
    
    def check_billing
      redirect_to checkout_billing_url and return false unless session[:bill_address] && session[:bill_address].valid?
      if @cart.payment_method.blank?
        flash[:error] = "Please select a payment method"
        redirect_to checkout_billing_url and return false
      end
    end
    
    def check_authorization 
      if @cart.payment_method == "Credit Card" && !@cart.card_authorization
        flash[:error] = "Credit card authorization failed. Please re-enter your billing information."
        redirect_to checkout_billing_url
        return false
      end
    end
    
    def set_step_heading(step = 0)
      total_steps = 4
      return nil unless step > 0 && step <= total_steps
      # processing is skipped if customer is not institution and cart has processable items...
      unless Customer::INSTITUTIONS.include?(current_user.category) && @cart && @cart.processing_count > 0
        step -= 1
        total_steps -= 1
      end
      @step_heading = "Step #{step} of #{total_steps} - "
    end
    
end
