class Admin::PriceChangesController < AdminController
  before_filter :load_price_change, :only => [:show, :edit, :update, :destroy]
  before_filter :build_price_change, :only => [:new, :create]
  before_filter :load_product
  
  def index
    if @product
      @search = @product.price_changes.search(params[:search])
    else
      @search = PriceChange.search(params[:search])
    end
    @price_changes = @search.paginate(:page => params[:page], :per_page => pager)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @price_changes }
    end
  end
  
  def show
    respond_to do |format|
      format.html
      format.xml  { render :xml => @price_change }
    end
  end
  
  def new
    @product = nil

    respond_to do |format|
      format.html
      format.xml  { render :xml => @price_change }
    end
  end

  def edit
    @product = @price_change.product_format.product
  end
  
  def create
    respond_to do |format|
      if @price_change.save
        flash[:notice] = 'Price change was successfully created.'
        format.html { redirect_to admin_price_changes_url }
        format.xml  { render :xml => @price_change, :status => :created, :location => @price_change }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @price_change.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @price_change.update_attributes(params[:price_change])
        flash[:notice] = 'Price change was successfully updated.'
        format.html { redirect_to admin_price_changes_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @price_change.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @price_change.destroy

    respond_to do |format|
      format.html { redirect_to admin_price_changes_url }
      format.xml  { head :ok }
    end
  end
  
  def format_options
    @product_formats = ProductFormat.where("product_id=?", params[:product_id]).all
    field_id = params[:field_id] || :price_change_product_format_id
    respond_to do |format|
      format.html
      format.xml
      format.js   {
        render :update do |page|
          page[field_id].replace_html :partial => 'admin/price_changes/format_options'
          if @product_formats.any?
            page[field_id].visual_effect :highlight, :startcolor => "#bbbbcc", :endcolor => "#E8EAE1"
          end
        end
      }
    end
  end
  
  protected

    def build_price_change
      @price_change = PriceChange.new(params[:price_change])
    end

    def load_price_change
      @price_change = PriceChange.find(params[:id])
      rescue Exception => e
        flash[:error] = 'Error finding price_change'.concat(" (#{e.message})")
        redirect_to admin_price_changes_url and return
    end

    def load_product
      @product = params[:product_id].blank? ? nil : Product.find(params[:product_id])
    rescue Exception => e
      flash[:error] = 'Error finding product'.concat(" (#{e.message})")
      redirect_to admin_price_changes_url and return
    end

end
