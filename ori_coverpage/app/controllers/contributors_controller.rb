class ContributorsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_contributor, :only => [:show]
  before_filter :load_product, :only => [:index]

  def index
    @page_title = "Contributors"
    if @product
      contributors = @product.contributors
    else
      contributors = Contributor
      remove_instance_variable(:@product)
    end
    @contributors = contributors.where('description is not null and description != ""').order('name ASC').paginate(:page => params[:page], :per_page => pager)
  end

  def show
    @page_title = "#{@contributor.name} - Contributors"
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @contributor.to_xml }
    end
  end
    
  protected
    
    def load_contributor
      @contributor = Contributor.find(params[:id])
    end

    def load_product
      @product = Product.find(params[:product_id]) rescue nil
    end

end
