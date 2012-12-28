class Admin::EditorialReviewsController < AdminController
  before_filter :build_editorial_review, :only => [:new, :create]
  before_filter :load_editorial_review, :only => [:show, :edit, :update, :destroy]
  before_filter :load_product

  def index
    if @product
      @search = @product.editorial_reviews.search(params[:search])
    else
      @search = EditorialReview.search(params[:search])
    end
    @page_title = "Editorial Reviews"
    @editorial_reviews = @search.paginate(:page => params[:page], :per_page => pager)
  end

  def create
    respond_to do |format|
      if @editorial_review.save
        flash[:notice] = 'Editorial Review was successfully created.'
        format.html { redirect_to editorial_reviews_url }
        format.xml  { head :created, :location => editorial_reviews_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @editorial_review.errors.to_xml }
      end
    end
  end

  def edit
    # refs #359
  end
  
  def update
    respond_to do |format|
      if @editorial_review.update_attributes(params[:editorial_review])
        flash[:notice] = 'Editorial Review was successfully updated.'
        format.html { redirect_to editorial_reviews_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @editorial_review.errors.to_xml }
      end
    end
  end

  def destroy
    @editorial_review.destroy

    respond_to do |format|
      flash[:notice] = 'Editorial Review was deleted.'
      format.html { redirect_to admin_editorial_reviews_url }
      format.xml  { head :ok }
    end
  end

  protected

    def build_editorial_review
      @editorial_review = EditorialReview.new(params[:editorial_review])
    end

    def load_editorial_review
      @editorial_review = EditorialReview.find(params[:id])
    end

    def load_product
      @product = params[:product_id].nil? ? nil : Product.find(params[:product_id])
    end
  end
