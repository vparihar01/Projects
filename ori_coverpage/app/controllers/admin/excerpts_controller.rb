class Admin::ExcerptsController < AdminController
  before_filter :build_excerpt, :only => [:new, :create]
  before_filter :load_excerpt, :only => [:show, :edit, :update, :destroy, :click, :read]

  def index
    @page_title = "Samples"
    @search = Excerpt.search(params[:search])
    @excerpts = @search.paginate(:page => params[:page], :per_page => pager)
  end

  # TODO: candidate for removal, delete commented block if deprecation accepted
#  def click
#    send_file(@excerpt.public_filename, :x_sendfile => CONFIG[:use_xsendfile])
#  end

  def new
    # refs #373 - rails 3 - having this blank method fixes the problem
  end

  def create
    respond_to do |format|
      if @excerpt.save
        flash[:notice] = 'Excerpt was successfully created.'
        format.html { redirect_to admin_excerpts_url }
        format.xml  { head :created, :location => admin_excerpts_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @excerpt.errors.to_xml }
      end
    end
  end

  def update
    respond_to do |format|
      if @excerpt.update_attributes(params[:excerpt])
        flash[:notice] = 'Excerpt was successfully updated.'
        format.html { redirect_to admin_excerpts_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @excerpt.errors.to_xml }
      end
    end
  end

  def destroy
    @excerpt.destroy
    respond_to do |format|
      format.html { redirect_to admin_excerpts_url }
      format.xml  { head :ok }
    end
  end

  # TODO: candidate for removal, delete commented block if deprecation is accepted
#  def read
#    @page_title = "#{@excerpt.title.name} - Excerpts"
#    render :layout => 'blank'
#  end

  protected

    def build_excerpt
      @excerpt = Excerpt.new(params[:excerpt])
    end

    def load_excerpt
      begin
    		@excerpt = Excerpt.find(params[:id])
    	rescue
  			flash[:error] = "Unknown ID"
  			redirect_to admin_excerpts_url
    	end
    end
end
