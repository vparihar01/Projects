class Admin::LinksController < AdminController
  before_filter :build_link, :only => [:new, :create]
  before_filter :load_link, :only => [:show, :edit, :update, :destroy, :click, :assign_product, :delete_product]
  before_filter :load_product

  def index
    if @product
      @search = @product.links.search(params[:search])
    else
      @search = Link.search(params[:search])
    end
    @links = @search.paginate(:page => params[:page], :per_page => pager)
    @page_title = (@product.nil? ? "" : "#{@product.name} - ").concat("Links")
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @links }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @link.to_xml }
    end
  end

  def create
    respond_to do |format|
      if @link.save
        flash[:notice] = 'Link was successfully created.'
        format.html { redirect_to admin_links_url }
        format.xml  { head :created, :location => admin_links_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @link.errors.to_xml }
      end
    end
  end

  def edit
    @page_title = "Edit - Links"
  end

  def update
    respond_to do |format|
      if @link.update_attributes(params[:link])
        flash[:notice] = 'Link was successfully updated.'
        format.html { redirect_to admin_links_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @link.errors.to_xml }
      end
    end
  end

  def destroy
    @link.destroy
    respond_to do |format|
      format.html { redirect_to admin_links_url }
      format.xml  { head :ok }
    end
  end

  def assign_product
    product = Product.find(params[:product_id])
    if @link && product
      respond_to do |format|
        if @link.products << product
          format.js {
            render :update do |page|
              page.insert_html :bottom, 'assignments', {:partial => 'admin/shared/product', :locals => {:product => product, :assignable => @link}}
              page.visual_effect :highlight, dom_id(product)
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product was successfully assigned.'
            redirect_to edit_admin_link_url(@link)
          }
          format.xml  { head :ok }
        else
          msg = "The product could not be assigned."
          format.js {
            render :update do |page|
              page.alert(msg)
            end
          }
          format.html {
            flash[:error] = msg
            redirect_to edit_admin_link_url(@link)
          }
          format.xml  { render :xml => @link.errors, :status => :unprocessable_entity }
        end
      end
    end
  end


  def delete_product
    product = @link.products.find(params[:product_id])
    if @link && product
      respond_to do |format|
        if @link.products.delete(product)
          format.js {
            render :update do |page|
              page.visual_effect(:fade, dom_id(product), :duration => CONFIG[:fade_duration])
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product assignment was successfully deleted.'
            redirect_to edit_admin_link_url(@link)
          }
          format.xml  { head :ok }
        else
          raise Exception, "Could not delete."
        end
      end
    end
    
  rescue Exception => e
    respond_to do |format|
      format.html {
        flash[:error] = 'Product assignment was NOT deleted.'
        redirect_to edit_admin_link_url(@link)
      }
      format.js {
        render :update do |page|
          page.alert('Product assignment was NOT deleted.')
        end
      }
    end
  end



  protected

    def build_link
      @link = Link.new(params[:link])
    end

    def load_link
      @link = Link.find(params[:id])
    end

    def load_product
      @product = params[:product_id].blank? ? nil : Product.find(params[:product_id])
    rescue Exception => e
      flash[:error] = e.message
      redirect_to admin_links_url and return
    end
end
