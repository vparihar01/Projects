class Admin::ContributorsController < AdminController
  before_filter :load_product
  before_filter :build_contributor, :only => [:new, :create]
  before_filter :load_contributor, :only => [:edit, :update, :destroy]
  
  def index
    if @product
      @search = @product.contributors.search(params[:search])
    else
      @search = Contributor.search(params[:search])
    end
    @contributors = @search.paginate(:page => params[:page], :per_page => pager)
    @page_title = (@product.nil? ? "" : "#{@product.name} - ").concat("Contributors")
  end

  def new
    @page_title = "New - Contributors"
  end

  def edit
    @page_title = "Edit - Contributors"
  end

  def create
    respond_to do |format|
      if @contributor.save
        flash[:notice] = 'Contributor was successfully created.'
        format.html { redirect_to admin_contributors_url }
        format.xml  { head :created, :location => admin_contributors_url }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @contributor.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @contributor.update_attributes(params[:contributor])
        flash[:notice] = 'Contributor was successfully updated.'
        format.html { redirect_to admin_contributors_url }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @contributor.errors.to_xml }
      end
    end
  end

  def destroy
    @contributor.destroy
    respond_to do |format|
      format.html { redirect_to admin_contributors_url }
      format.xml  { head :ok }
    end
  end

  protected

  def build_contributor
    @contributor = Contributor.new(params[:contributor])
  end

  def load_contributor
    @contributor = Contributor.find(params[:id])
  end

  def load_product
    @product = params[:product_id].nil? ? nil : Product.find(params[:product_id])
  end

end
