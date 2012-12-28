class Admin::CategoriesController  < AdminController
  before_filter :build_category, :only => [:new, :create]
  before_filter :load_category, :only => [:show, :edit, :update, :destroy, :assign_product, :delete_product]

  def index
    @page_title = "Subjects"
    @search = Category.search(params[:search])
    @categories = @search.paginate(:page => params[:page], :per_page => pager)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
    end
  end

  def show
    @page_title = "#{@category.name} - Subjects"
    @products = @category.products.available.grade(params[:grade]).order('name ASC').paginate(:page => params[:page], :per_page => pager)
    respond_to do |format|
      format.html #{ render :layout => 'shop' } # show.rhtml
      format.xml  { render :xml => @category.to_xml }
    end
  end

  def new
    @page_title = "New - Subjects"
  end

  def edit
    @page_title = "Edit - Subjects"
  end

  def create
    respond_to do |format|
      if @category.save
        flash[:notice] = 'Category was successfully created.'
        format.html { redirect_to admin_categories_url }
        format.xml  { head :created, :location => admin_categories_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to admin_categories_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors.to_xml }
      end
    end
  end

  def destroy
    @category.destroy
    respond_to do |format|
      format.html { redirect_to admin_categories_url }
      format.xml  { head :ok }
    end
  end

  def assign_product
    product = Product.find(params[:product_id])
    if @category && product
      respond_to do |format|
        if @category.products << product
          format.js {
            render :update do |page|
              page.insert_html :bottom, 'assignments', {:partial => 'admin/shared/product', :locals => {:product => product, :assignable => @category}}
              page.visual_effect :highlight, dom_id(product)
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product was successfully assigned.'
            redirect_to edit_admin_category_url(@category)
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
            redirect_to edit_admin_category_url(@category)
          }
          format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def delete_product
    product = @category.products.find(params[:product_id])
    if @category && product
      respond_to do |format|
        if @category.products.delete(product)
          format.js {
            render :update do |page|
              page.visual_effect(:fade, dom_id(product), :duration => CONFIG[:fade_duration])
              page[:assignment_form].reset
            end
          }
          format.html {
            flash[:notice] = 'Product assignment was successfully deleted.'
            redirect_to edit_admin_category_url(@category)
          }
          format.xml  { head :ok }
        else
          flash[:error] = 'Product assignment was NOT deleted.'
        end
      end
    end
  end

  protected

    def build_category
      @category = Category.new(params[:category])
    end

    def load_category
      @category = Category.find(params[:id])
    end

end
