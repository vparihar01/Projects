class Admin::HeadlinesController < AdminController
  before_filter :build_headline, :only => [:new, :create]
  before_filter :load_headline, :only => [:show, :edit, :update, :destroy]

  def index
    @search = Headline.search(params[:search])
    @headlines = @search.paginate(:page => params[:page], :per_page => pager)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @headlines.to_xml }
    end
  end
  
  def new
    # refs #365 -- same type of error, same solution
  end

  def show
    @page_title = "#{@headline.title} - Headlines"
    respond_to do |format|
      format.html
      format.xml  { render :xml => @headline.to_xml }
    end
  end

  def create
    respond_to do |format|
      if @headline.save
        flash[:notice] = 'Headline was successfully created.'
        format.html { redirect_to admin_headlines_url }
        format.xml  { head :created, :location => admin_headlines_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @headline.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @headline.update_attributes(params[:headline])
        flash[:notice] = 'Headline was successfully updated.'
        format.html { redirect_to admin_headlines_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @headline.errors.to_xml }
      end
    end
  end

  def destroy
    @headline.destroy
    respond_to do |format|
      format.html { redirect_to admin_headlines_url }
      format.xml  { head :ok }
    end
  end
  
  protected
    
    def build_headline
      @headline = Headline.new(params[:headline])
    end
    
    def load_headline
      @headline = Headline.find(params[:id])
    end
  
end
