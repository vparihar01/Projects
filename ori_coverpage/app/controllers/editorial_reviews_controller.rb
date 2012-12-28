class EditorialReviewsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_editorial_review, :only => [:show]
  before_filter :init_cart

  def index
    @page_title = "Editorial Reviews"
    # TODO: decide if admin user should see non-published reviews on the current site (that is not the case now) and delete / uncomment the following line accordingly
    #@editorial_reviews = (admin?) ? EditorialReview.paginate(:all, :order => "written_on DESC", :page => params[:page], :per_page => pager) : EditorialReview.paginate_ok(:all, :order => "written_on DESC", :page => params[:page], :per_page => pager)
    @editorial_reviews = EditorialReview.order("written_on DESC").ok.paginate(:page => params[:page], :per_page => pager)
  end
  
  def search
    @product = Product.find_by_isbn(params[:isbn].gsub('-',''))
    # TODO: decide if admin user should see non-published reviews on the current site (that is not the case now) and delete / uncomment the following line accordingly
    #@editorial_reviews = @product ? ( admin? ? @product.editorial_reviews.paginate(:all, :page => params[:page], :per_page => pager) : @product.editorial_reviews.paginate_ok(:all, :page => params[:page], :per_page => pager) ) : []
    @editorial_reviews = @product ?  @product.editorial_reviews.order("written_on DESC").ok.paginate(:page => params[:page], :per_page => pager) : []
    render :index
  end

  def show
    @product = @editorial_review.products.first
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @editorial_review.to_xml }
    end
  end
  
  protected
    def load_editorial_review
      @editorial_review = EditorialReview.find(params[:id])
    end
  
end
