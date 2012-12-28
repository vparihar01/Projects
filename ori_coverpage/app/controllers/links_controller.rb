class LinksController < ApplicationController
  skip_before_filter :login_required
  before_filter :admin_required, :except => [:index, :show, :popular, :recommended, :click, :search]
  before_filter :load_link, :only => [:show, :click]
  before_filter :load_product, :only => [:index]
  before_filter :set_page_number, :only => [:index, :search, :popular]

  def index
    @page_title = "Research Assistant - Links"
    if @product
      links = @product.links
    else
      links = Link
      remove_instance_variable(:@product)
    end
    @links = admin? ? links.paginate(:page => @page, :per_page => pager) : links.ok.select("distinct links.*").paginate(:page => @page, :per_page => pager)
  end
  
  def search
    search_pairs = Product.process_search_params(params)
    @products = Product.advanced_search(search_pairs).sort_by(&:name_less_article)
    if @products.size == 1
      @product = @products.first
      @links = admin? ? @product.links.paginate(:page => @page, :per_page => pager) : @product.links.ok.select("distinct links.*").paginate(:page => @page, :per_page => pager)
    else
      @product = nil
      @links = []
    end
    render :index
  end

  def show
    respond_to do |format|
      format.html { render }
      format.xml  { render :xml => @link.to_xml }
    end
  end

  def click
    if @link && @link.is_ok?
      @link.mark_as_viewed unless admin?
      redirect_to(@link.url)
    else
      if @link && admin?
        # TODO why not redirect to the admin/link/#id path instead? consider...
        redirect_to(@link.url)
      else
        flash[:notice] = 'Invalid link'
        redirect_to links_url
      end
    end
  end

  def recommended
    @kids = Link.kid_items
    @adults = Link.adult_items
  end

  def popular
    @links = ( admin? ? Link.order('views DESC').paginate(:page => @page, :per_page => pager) : Link.order('views DESC').ok.paginate(:page => @page, :per_page => pager) )
  end
  
  protected
    
    def load_link
      @link = Link.find(params[:id])
    end
  
    def load_product
      @product = Product.find(params[:product_id]) rescue nil
    end
    
    def set_page_number
      @page = params[:page].to_i == 0 ? 1 : params[:page].to_i
    end

end
