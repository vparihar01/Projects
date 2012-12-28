class TeachingGuidesController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_teaching_guide, :only => [:show, :download]
  before_filter :load_tags, :only => [:index, :tag]

  def index
    @page_title = "Teaching Guides"
    @teaching_guides = TeachingGuide.order(:name)
  end

  def show
    @product = @teaching_guide.products.first
    @page_title = @teaching_guide.name
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @teaching_guide.to_xml }
    end
  end

  def download
    if @teaching_guide.document_exist?
      @teaching_guide.mark_as_downloaded unless admin?
      send_file(@teaching_guide.document.current_path, :x_sendfile => CONFIG[:use_xsendfile])
    else
      flash[:notice] = "The file you requested is no longer available."
      redirect_to teaching_guides_url
    end
  end

  def tag
    @page_title = "#{params[:tag].titlecase} - Teaching Guides"
    @teaching_guides = TeachingGuide.order(:name).find_tagged_with(params[:tag])
    render :index
  end

  protected

  def load_teaching_guide
    @teaching_guide = TeachingGuide.find(params[:id])
  end

  def load_tags
    @tags = TeachingGuide.tag_counts # returns all the tags used
  end
end
