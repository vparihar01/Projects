class Admin::PagesController < AdminController

  def index
    @search = Page.search(params[:search])
    #@page_title = "Pages - Administration"
    @pages = @search.paginate(:page => params[:page], :per_page => pager)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end

  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(params[:page])
    if @page.save
      flash[:notice] = 'Page was successfully created.'
      redirect_to admin_pages_path
    else
      render :action => 'new'
    end
  end

  def edit
    @page = Page.find(params[:id])
  end

  def update
    @page = Page.find(params[:id])
    if @page.update_attributes(params[:page])
      flash[:notice] = 'Page was successfully updated.'
      redirect_to admin_pages_path
    else
        render :action => 'edit'
    end
  end

  def destroy
    @page = Page.find(params[:id])
    if @page.is_protected?
      flash[:error] = "This page is protected and so cannot be deleted."
    else
      @page.destroy
      flash[:notice] = 'Page was successfully deleted.'
    end
    redirect_to admin_pages_path
  end
end
