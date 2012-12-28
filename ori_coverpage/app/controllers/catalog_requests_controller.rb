class CatalogRequestsController < ApplicationController
  skip_before_filter :login_required

  def new
    # build catalog request (relevant part)
    @catalog_request = CatalogRequest.new
    if !logged_in? || current_user.primary_address.nil?
      @postal_code = PostalCode.new
      @address = Address.new
      @address.postal_code = @postal_code
    else
      @address = current_user.primary_address
      @postal_code = @address.postal_code
    end
    @catalog_request.address = @address
    # catalog request built
  end

  def create
    # build catalog request (relevant part)
    @catalog_request = CatalogRequest.new
    @postal_code = ( PostalCode.find_or_create_by_name_and_zone_id(params[:postal_code][:name], params[:postal_code][:zone_id]) || PostalCode.new(params[:postal_code]) )
    @address = Address.new(params[:catalog_request][:address_attributes])
    @address.postal_code = @postal_code
    @catalog_request.address = @address
    # catalog request built
    respond_to do |format|
      if @catalog_request.save
        flash[:notice] = 'Catalog request was successfully created.'
        if admin?
          format.html { redirect_to admin_catalog_requests_url }
          format.xml  { head :created, :location => admin_catalog_requests_url }
        else
          format.html { redirect_to public_page_path(:help) }
          format.xml  { head :created, :location => root_path }
        end 
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @catalog_request.errors.to_xml }
      end
    end
  end

end
