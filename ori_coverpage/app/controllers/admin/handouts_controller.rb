class Admin::HandoutsController < AdminController
  before_filter :build_handout, :only => [:new, :create]
  before_filter :load_handout, :only => [:show, :edit, :update, :destroy]
  before_filter :load_teaching_guide

  def index
    if @teaching_guide
      @search = @teaching_guide.handouts.search(params[:search])
    else
      @search = Handout.search(params[:search])
    end
    @page_title = "Handouts"
    @handouts = @search.paginate(:page => params[:page], :per_page => pager)
  end

  def show
    redirect_to handout_url(@handout)
  end

  def create
    respond_to do |format|
      if @handout.save
        flash[:notice] = 'Handout was successfully created.'
        format.html { redirect_to admin_handouts_url }
        format.xml  { head :created, :location => admin_handouts_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @handout.errors.to_xml }
      end
    end
  end

  def edit
    # refs #359
  end
  
  def update
    respond_to do |format|
      if @handout.update_attributes(params[:handout])
        flash[:notice] = 'Handout was successfully updated.'
        format.html { redirect_to admin_handouts_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @handout.errors.to_xml }
      end
    end
  end

  def destroy
    @handout.destroy
    respond_to do |format|
      flash[:notice] = 'Handout was deleted.'
      format.html { redirect_to admin_handouts_url }
      format.xml  { head :ok }
    end
  end

  protected

  def build_handout
    @handout = Handout.new(params[:handout])
  end

  def load_handout
    @handout = Handout.find(params[:id])
  end

  def load_teaching_guide
    @teaching_guide = params[:teaching_guide_id].nil? ? nil : Product.find(params[:teaching_guide_id])
  end

end
