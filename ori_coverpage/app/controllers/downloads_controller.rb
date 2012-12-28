class DownloadsController < ApplicationController
  skip_before_filter :login_required

  before_filter :load_download, :only => [:show, :click]
  before_filter :load_tags, :only => [:index, :search, :tag]

  def index
    if admin?
      # @downloads = Download.order('created_at DESC').paginate( :page => params[:page], :per_page => pager)
      @downloads = Download.order(:title)
    else
      # @downloads = Download.where("is_visible=true").order('created_at DESC').paginate( :page => params[:page], :per_page => pager)
      @downloads = Download.where("is_visible=true").order(:title)
    end
  end

  def tag
    @page_title = "#{params[:tag].titlecase} - Downloads"
    if admin?
      # @downloads = Download.paginate_tagged(params[:tag], :page => params[:page], :per_page => pager)
      @downloads = Download.order(:title).find_tagged_with(params[:tag])
    else
      # @downloads = Download.paginate_tagged(params[:tag], :page => params[:page], :per_page => pager, :conditions => "is_visible=true")
      @downloads = Download.where("is_visible=true").order(:title).find_tagged_with(params[:tag])
    end
    render :index
  end

  def click
    if @download.is_visible || admin?
      @download.mark_as_viewed unless admin?
      send_file(@download.public_filename, :x_sendfile => CONFIG[:use_xsendfile])
    else
      flash[:notice] = "The file you requested is no longer available."
      redirect_to downloads_url
    end
  end

  def show
    unless @download.is_visible || admin?
      flash[:notice] = "The file you requested is no longer available."
      redirect_to downloads_url
    end
  end

  protected
        
    def load_download
      begin
        @download = Download.find(params[:id])
      rescue
        flash[:error] = "Unknown ID"
        redirect_to downloads_url
      end
    end
    
    def load_tags
      @tags = Download.tag_counts # returns all the tags used
    end
end
