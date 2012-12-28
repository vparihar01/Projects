class Admin::FaqsController < AdminController
  before_filter :load_faq, :only => [:show, :edit, :update, :destroy]
  before_filter :build_faq, :only => [:new, :create]

  def index
    @search = Faq.search(params[:search])
    @faqs = @search.paginate(:page => params[:page], :per_page => pager)
  end
  
  def new
    # issue #365 -- if including a blank new, the callbacks are run in proper order whether or not in test mode
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @faq.to_xml }
    end
  end

  def create
    respond_to do |format|
      if @faq.save
        flash[:notice] = 'Faq was successfully created.'
        format.html { redirect_to admin_faqs_url }
        format.xml  { head :created, :location => admin_faqs_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @faq.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @faq.update_attributes(params[:faq])
        flash[:notice] = 'Faq was successfully updated.'
        format.html { redirect_to admin_faqs_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @faq.errors.to_xml }
      end
    end
  end

  def destroy
    @faq.destroy
    respond_to do |format|
      format.html { redirect_to admin_faqs_url }
      format.xml  { head :ok }
    end
  end

  protected

    def build_faq
      @faq = Faq.new(params[:faq])
    end

    def load_faq
      @faq = Faq.find(params[:id])
    end

end
