module VersionedModelControllerMethods
  def self.included(base)
    base.send :before_filter, :load_versionable, :only => [:revert_to_version, :versions, :changeset, :compare]
    base.send :helper_method, :edit_versionable_path, :pname, :versions_path, :versionables_path
  end

  def revert_to_version
    # TODO: Since revert_to! always returns true, test if version number is valid manually
    if params[:version_number] == '1' || version = @versionable.versions.find_by_number(params[:version_number])
      if @versionable.revert_to!(params[:version_number].to_i) # TODO: this seems to return true in all cases
        @versionable.reload
        flash[:notice] = "#{@versionable.class.to_s} data successfully reverted to version #{params[:version_number]} as version #{@versionable.version}."
        redirect_to edit_versionable_path(@versionable)
      else
        flash[:error] = "Failed to revert to version #{params[:version_number]}."
        redirect_to versions_path(@versionable)
      end
    else
      version_number_not_found
    end
  end

  def versions
    @versions = @versionable.versions
    render 'admin/versions/index'
  end
  
  def compare
    if params[:version_number] == '1' || @version = @versionable.versions.find_by_number(params[:version_number])
      @changes = @versionable.changes_between(params[:version_number].to_i, @versionable.version)
      render_changeset
    else
      version_number_not_found
    end
  end

  def changeset
    if @version = @versionable.versions.find_by_number(params[:version_number])
      @title = "Version #{@version.number} Changeset"
      @before_label = "Version #{@version.number - 1}"
      @after_label = "Version #{@version.number}"
      @changes = @version.changes
      render_changeset
    else
      version_number_not_found
    end
  end

  protected
    def load_versionable
      @versionable = self.instance_variable_set('@' + cname,  scoper.find(params[:id]))
    rescue Exception => e
      flash[:error] = "Failed to load versionable: #{e}"
      redirect_to versionables_path and return
    end

    def pname
      self.class.to_s.underscore.gsub(/\//, "_").gsub(/_controller/,"").singularize
    end

    def cname
      @cname ||= controller_name.singularize
    end

    def scoper
      Object.const_get(cname.classify)
    end
    
    def versionables_path
      eval("#{pname.pluralize}_path")
    end

    def edit_versionable_path(versionable)
      eval("edit_#{pname}_path(#{versionable.id})")
    end
    
    def versions_path(versionable)
      eval("versions_#{pname}_path(versionable)")
    end
    
    def version_number_not_found
      flash[:error] = "Error finding version number #{params[:version_number]}."
      redirect_to versions_path(@versionable)
    end
    
    def render_changeset
      respond_to do |format|
        format.html { render "admin/versions/compare" }
        format.js   {
          render :update do |page|
            # IE7 issue: couldn't center modal in browser window
            # created kludge to calculate center based on browser width and image width
            width = 640
            page << "function centerElement(element) {return (document.viewport.getScrollOffsets()[0]+document.viewport.getWidth()-#{width})/2+'px';}"
            page << "$('modal').setStyle({'left': centerElement('modal')})"
            page[:modal].replace_html :partial => "admin/versions/compare", :layout => "admin/versions/window", :locals => { :version => @version, :versionable => @versionable, :changes => @changes, :before_label => @before_label, :after_label => @after_label }
            page.draggable(:modal, {:revert => false})
            page.visual_effect(:appear, :modal, {:queue => 'front', :duration => 0.7})
            page.visual_effect(:appear, :screen, {:to => 0.5, :queue => 'front', :duration => CONFIG[:fade_duration]})
          end
        }
      end
    end
    
end