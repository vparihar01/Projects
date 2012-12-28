class Admin::TeachingGuidesController < AdminController
  before_filter :build_teaching_guide, :only => [:new, :create]
  before_filter :load_teaching_guide, :only => [:show, :edit, :update, :destroy]
  before_filter :load_product

  def index
    if @product
      @search = @product.teaching_guides.search(params[:search])
    else
      @search = TeachingGuide.search(params[:search])
    end
    @page_title = "Teaching Guides"
    @teaching_guides = @search.paginate(:page => params[:page], :per_page => pager)
  end

  def show
    redirect_to teaching_guide_url(@teaching_guide)
  end

  def create
    respond_to do |format|
      if @teaching_guide.save
        flash[:notice] = 'Teaching Guide was successfully created.'
        format.html { redirect_to admin_teaching_guides_url }
        format.xml  { head :created, :location => admin_teaching_guides_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @teaching_guide.errors.to_xml }
      end
    end
  end

  def edit
    # refs #359
  end
  
  def update
    respond_to do |format|
      if @teaching_guide.update_attributes(params[:teaching_guide])
        flash[:notice] = 'Teaching Guide was successfully updated.'
        format.html { redirect_to admin_teaching_guides_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @teaching_guide.errors.to_xml }
      end
    end
  end

  def destroy
    @teaching_guide.destroy

    respond_to do |format|
      flash[:notice] = 'Teaching Guide was deleted.'
      format.html { redirect_to admin_teaching_guides_url }
      format.xml  { head :ok }
    end
  end

  protected

  def build_teaching_guide
    @teaching_guide = TeachingGuide.new(params[:teaching_guide])
  end

  def load_teaching_guide
    @teaching_guide = TeachingGuide.find(params[:id])
  end

  def load_product
    @product = params[:product_id].nil? ? nil : Product.find(params[:product_id])
  end

end
