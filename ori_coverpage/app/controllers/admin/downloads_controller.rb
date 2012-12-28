class Admin::DownloadsController < AdminController
  before_filter :build_download, :only => [:new, :create]
  before_filter :load_download, :only => [:show, :edit, :update, :destroy, :rename, :toggle]

  def index
    @search = Download.search(params[:search])
    @downloads = @search.paginate(:page => params[:page], :per_page => pager)
  end

  def toggle
    respond_to do |format|
      if @download.toggle!(:is_visible)
        format.js {
          render :update do |page|
            if params[:admin] == "1"
              partial = 'admin/downloads/download'
            else
              partial = (session[:layout].nil? || session[:layout] == 'x' ? 'downloads/xdownload' : 'downloads/download')
            end
            page[dom_id(@download)].replace :partial => partial, :locals => {:download  => @download, :show_admin => true}
            page.visual_effect :highlight, dom_id(@download)
          end
        }
        format.html {
          flash[:notice] = 'Download was successfully updated.'
          redirect_to admin_download_url(@download)
        }
        format.xml { head :ok }
      else
        msg = "The download could not be updated."
        format.js {
          render :update do |page|
            page.alert(msg)
          end
        }
        format.html {
          flash[:error] = msg
          redirect_to admin_download_url(@download)
        }
        format.xml  { render :xml => @download.errors, :status => :unprocessable_entity }
      end
    end
  end

  def create
    respond_to do |format|
      if @download.save
        flash[:notice] = 'Download was successfully created.'
        format.html { redirect_to admin_downloads_url }
        format.xml  { head :created, :location => admin_downloads_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @download.errors.to_xml }
      end
    end
  end
  
  def edit
    # refs #359
  end

  def update
    respond_to do |format|
      if @download.update_attributes(params[:download])
        flash[:notice] = 'Download was successfully updated.'
        format.html { redirect_to admin_downloads_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @download.errors.to_xml }
      end
    end
  end

  def destroy
    @download.destroy
    flash[:notice] = 'Download was successfully deleted.'
    respond_to do |format|
      format.html { redirect_to admin_downloads_url }
      format.xml  { head :ok }
    end
  end

  def rename
    # throws error if not present, tries to use application layout
  end

  protected

    def build_download
      @download = Download.new(params[:download])
    end

    def load_download
      begin
        @download = Download.find(params[:id])
      rescue
        flash[:error] = "Unknown ID"
        redirect_to admin_downloads_url
      end
    end

end
