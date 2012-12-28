class Admin::CatalogRequestsController < AdminController
  before_filter :load_catalog_request, :only => [:show, :edit, :update, :destroy]
  
  def index
    respond_to do |format|
      format.html {
        @catalog_requests = CatalogRequest.order("created_at DESC").paginate(:page => params[:page], :per_page => pager)
      }
      format.xml  { render :xml => CatalogRequest.order("created_at DESC").all.to_xml(:include => :address, :except => [:addressable_type, :addressable_id, :is_primary], :methods => [:zone_name, :postal_code_name, :country_name], :skip_types => true) }
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @catalog_request.to_xml(:include => :address, :except => [:addressable_type, :addressable_id, :is_primary], :methods => [:zone_name, :postal_code_name, :country_name], :skip_types => true) }
    end
  end

  def export
    @catalog_requests = CatalogRequest.order("created_at DESC").all
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename=catalog_requests.csv'
    render :action => 'export', :layout => false
  end

  def update
    respond_to do |format|
      if @catalog_request.update_attributes(params[:catalog_request]) && @catalog_request.address.update_attributes(params[:address])
        flash[:notice] = 'Catalog request was successfully updated.'
        format.html { redirect_to admin_catalog_requests_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @catalog_request.errors.to_xml }
      end
    end
  end

  def destroy
    @catalog_request.destroy
    respond_to do |format|
      format.html { redirect_to admin_catalog_requests_url }
      format.xml  { head :ok }
    end
  end

  protected
  
    def load_catalog_request
      if @catalog_request = CatalogRequest.find(params[:id])
        @address = @catalog_request.address
        @postal_code = @address.postal_code
      end

    rescue Exception => e
        flash[:error] = 'Error finding catalog request'.concat(" (#{e.message})")
        redirect_to admin_catalog_requests_url and return
    end

end
