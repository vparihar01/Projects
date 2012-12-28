class Admin::ErrataController < AdminController
  before_filter :load_erratum, :only => [:show, :edit, :update, :destroy]
  before_filter :build_erratum, :only => [:new, :create]
  before_filter :load_product
  
  def index
    if @product
      @search = @product.errata.search(params[:search])
    else
      @search = Erratum.search(params[:search])
    end
    @errata = @search.paginate(:page => params[:page], :per_page => pager)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @errata }
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @erratum }
    end
  end
  
  def new
    @erratum.user_id = @current_user.id
    @erratum.email = @current_user.email
    @erratum.name = @current_user.name
    @product = nil

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @erratum }
    end
  end

  def edit
    @product = @erratum.product_format.product
  end
  
  def create
    respond_to do |format|
      if @erratum.save
        flash[:notice] = 'Erratum was successfully created.'
        #format.html { redirect_to(@erratum) }
        format.html { redirect_to admin_errata_url }
        format.xml  { render :xml => @erratum, :status => :created, :location => @erratum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @erratum.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |format|
      if @erratum.update_attributes(params[:erratum])
        flash[:notice] = 'Erratum was successfully updated.'
        format.html { redirect_to admin_errata_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @erratum.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @erratum.destroy

    respond_to do |format|
      format.html { redirect_to admin_errata_url }
      format.xml  { head :ok }
    end
  end

  def set_status
    @erratum = Erratum.find(params[:id])
    @erratum.update_attribute(:status, params[:status]) if @erratum.status != params[:status]
    flash[:notice] = "The status has been updated."
    redirect_to admin_erratum_path(@erratum)
  rescue => e
    flash[:error] = e.message
    redirect_to @erratum.nil? ? admin_errata_path : admin_erratum_path(@erratum)
  end
  
  def format_options
    @product_formats = ProductFormat.where("product_id=?", params[:product_id]).all
    field_id = params[:field_id] || :erratum_product_format_id
    respond_to do |format|
      format.html 
      format.xml
      format.js   {
        render :update do |page|
          page[field_id].replace_html :partial => 'admin/errata/format_options'
          if @product_formats.any?
            page[field_id].visual_effect :highlight, :startcolor => "#bbbbcc", :endcolor => "#E8EAE1"
          end
        end
      }
    end
  end
  
  protected

    def build_erratum
      @erratum = Erratum.new(params[:erratum])
    end

    def load_erratum
      @erratum = Erratum.find(params[:id])
      rescue Exception => e
        flash[:error] = 'Error finding erratum'.concat(" (#{e.message})")
        redirect_to admin_errata_url and return
    end

    def load_product
      @product = params[:product_id].blank? ? nil : Product.find(params[:product_id])
    rescue Exception => e
      flash[:error] = 'Error finding product'.concat(" (#{e.message})")
      redirect_to admin_errata_url and return
    end

end
