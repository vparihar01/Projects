class HandoutsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_handout, :only => [:show, :download]

  def index
    @page_title = "Handouts"
    @handouts = Handout.order(:name).paginate(:page => params[:page], :per_page => pager)
  end

  def show
    @teaching_guide = @handout.teaching_guide
    @page_title = @handout.name
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @handout.to_xml }
    end
  end

  def download
    if @handout.document_exist?
      @handout.mark_as_downloaded unless admin?
      send_file(@handout.document.current_path, :x_sendfile => CONFIG[:use_xsendfile])
    else
      flash[:notice] = "The file you requested is no longer available."
      redirect_to handouts_url
    end
  end

  protected

  def load_handout
    @handout = Handout.find(params[:id])
  end

end
