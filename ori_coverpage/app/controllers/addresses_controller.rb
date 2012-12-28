class AddressesController < ApplicationController
  before_filter :build_address, :only => [:new, :create]
  before_filter :load_address, :only => [:show, :edit, :update, :delete, :destroy, :toggle_primary]

  def index
    @addresses = current_user.addresses
  end

  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @address.to_xml }
    end
  end
  
  def new
    render_new_action
  end

  def create
    respond_to do |format|
      if @address.save
        flash[:notice] = 'Address was successfully created.'
        set_address_session_var
        format.html { redirect_to redirect_url }
        format.xml  { head :created, :location => addresses_url() }
      else
        format.html { render_new_action }
        format.xml  { render :xml => @address.errors.to_xml }
      end
    end 
  end

  def edit
    render_edit_action
  end

  def update
    respond_to do |format|
      new_postal_code = PostalCode.find_or_create_by_name_and_zone_id(params[:postal_code][:name], params[:postal_code][:zone_id]) unless params[:postal_code].nil?
      params[:address][:postal_code_id] = new_postal_code.id unless params[:address].nil? || new_postal_code.nil?
      if @address.update_attributes(params[:address])
        flash[:notice] = 'Address was successfully updated.'
        format.html { redirect_to redirect_url }
        format.xml  { head :ok }
      else
        format.html { render_edit_action }
        format.xml  { render :xml => @address.errors.to_xml }
      end
    end
  end

  def destroy    
    @address.destroy   
    respond_to do |format|
      format.html { redirect_to redirect_url }
      format.xml  { head :ok }
    end
  end

  def toggle_primary
    @address.toggle!(:is_primary)
    redirect_to addresses_url()
  end
    
  def update_province
    postal_code = PostalCode.find_by_name(params[:postal_code])
    zone_id = postal_code.try(:zone_id)
    country_id = postal_code.try(:zone).try(:country_id)
    respond_to do |format|
      format.js {
        render :update do |page|
          page[:postal_code_zone_id].value = zone_id.to_s
          page[:sales_team_address_attributes_country_id].value = country_id.to_s
          page[:postal_code_zone_id].visual_effect :highlight
          page[:sales_team_address_attributes_country_id].visual_effect :highlight
        end
      }
    end
  end

  protected
  
    def build_address
      if @address = current_user.addresses.build(params[:address])
        build_postal_code
        # params[:address][:postal_code_id] = @postal_code.id unless params[:address].nil?
        @address.postal_code = @postal_code
      end
    end

    def load_address
      find_address_by_id_and_protect
      load_postal_code
    end

    def find_address_by_id_and_protect
      unless @address = current_user.addresses.find_by_id(params[:id])
        flash[:error] = 'Unauthorized.'
        redirect_to addresses_url() and return
      end
    end
    
    def load_postal_code
      unless @address.nil?
        unless @postal_code = @address.postal_code
          build_postal_code
          @address.postal_code = @postal_code
        end
      end
    end
    
    def build_postal_code
      if params[:postal_code].nil? || params[:postal_code][:name].blank? || params[:postal_code][:zone_id].blank?
        @postal_code = PostalCode.new
      else
        @postal_code = PostalCode.find_or_create_by_name_and_zone_id(params[:postal_code][:name], params[:postal_code][:zone_id])
      end
    end

    def address_type
      params[:address_type] == 'bill_address' ? 'billing' : 'shipping'
    end
    
    def redirect_url
      checkout_scope? ? self.send("checkout_#{address_type}_url") : addresses_url
    end
    
    def render_new_action
      if checkout_scope?
        @force_tab = ""
        @page_title = "New - #{address_type.titleize} Address - Checkout"
        render :action => 'new', :layout => 'checkout'
      else
        @page_title = "New - Addresses"
        render :action => 'new'
      end
    end
    
    def render_edit_action
      if checkout_scope?
        @address.valid?       # run validations in to trigger outputting any errors on existing addresses
        @force_tab = ""
        @page_title = "New - #{address_type.titleize} Address - Checkout"
        render :action => 'edit', :layout => 'checkout'
      else
        @page_title = "New - Addresses"
        render :action => 'edit'
      end
    end
    
    def set_address_session_var
      session[(params[:address_type] == 'bill_address' ? :bill_address : :ship_address)] = @address.id
    end
end
