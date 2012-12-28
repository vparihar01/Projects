class CollectionsController < ApplicationController
  skip_before_filter :login_required
  before_filter :init_cart
  
  def index
    @page_title = "Series"
    if params[:name]
      filtered = Collection.name_like(params[:name])
    else
      filtered = Collection.roots
    end
    filtered = admin? ? filtered : filtered.released
    @collections = filtered.order("name ASC").paginate(:page => params[:page], :per_page => pager)
  end

  def show
    @collection = Collection.find(params[:id])
    @page_title = "#{@collection.name} - Series"
    @titles = @collection.titles.available.paginate(:page => params[:page], :per_page => pager)
    @subcollections = @collection.children.where('collections.released_on <= NOW()').order(:name)
    @assemblies = @collection.assemblies.available.join_formats_with_distinct.active
    render_show
  end

  private

    def render_show
      if !@collection.released?
        if admin?
          flash.now[:notice] = "To be released on #{@collection.released_on}."
          render :layout => 'admin' and return
        else
          flash[:error] = "Series not yet released."
          redirect_to root_url and return
        end
      end
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @collection.to_xml }
      end
    end

end
