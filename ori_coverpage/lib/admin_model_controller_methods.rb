module AdminModelControllerMethods
  def self.included(base)
    base.send :before_filter, :build_object, :only => [ :new, :create ]
    base.send :before_filter, :load_object, :only => [ :show, :edit, :update, :destroy ]
  end
  
  def index
    @search = scoper.search(params[:search])
    self.instance_variable_set( '@' + self.controller_name,
      @search.paginate(:page => params[:page], :per_page => pager) )
  end
  
  def create
    if @obj.save
      flash[:notice] = "#{cname.humanize.capitalize} was successfully created."
      redirect_back_or_default redirect_url
    else
      render :action => 'new'
    end
  end

  def update
    if @obj.update_attributes(params[cname])
      # fix for :type attribute updates
      # see this warning in the logs...
      # WARNING: Can't mass-assign these protected attributes: type
      unless params[cname][:type].nil? || @obj[:type] == params[cname][:type]
        logger.debug "Type attribute detected. It was likely not updated. Updating it..."
        @obj[:type] = params[cname][:type]
        @obj.save
        logger.debug "Type attribute updated."
      end
      # end fix
      flash[:notice] = "#{cname.humanize.capitalize} was successfully updated."
      redirect_back_or_default redirect_url
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    if !@obj.nil?
      @result = @obj.destroy
      respond_to do |wants|
        wants.html do
          if @result
            flash[:notice] = "#{cname.humanize.capitalize} was successfully deleted."
            redirect_back_or_default redirect_url
          else
            render :action => 'show'
          end
        end

        wants.js do
          render :update do |page|
            if @result
              page.remove "#{@cname}_#{@obj.id}"
            else
              page.alert "Errors deleting #{@obj.class.to_s.capitalize}: #{@obj.errors.full_messages.to_sentence}"
            end
          end
        end
      end
    else
      redirect_back_or_default redirect_url
    end
  end
  
  def sort
    scoper.all.each do |item|
      item.update_attribute(:position, params["#{cname}_list"].index(item.id.to_s) + 1)
    end
    render :nothing => true
  end
  
  protected
  
    def cname
      @cname ||= controller_name.singularize
    end
    
    def set_object
      @obj ||= self.instance_variable_get('@' + cname)
    end
    
    def load_object
      @obj = self.instance_variable_set('@' + cname,  scoper.find(params[:id]))
    rescue Exception => e
      flash[:error] = "Unknown ID : #{e}"
      @obj = self.instance_variable_set('@' + cname, nil)
    end
    
    def build_object
      @obj = self.instance_variable_set('@' + cname,
        scoper.is_a?(Class) ? scoper.new(params[cname]) : scoper.build(params[cname]))
    end
    
    def scoper
      Object.const_get(cname.classify)
    end
    
    def redirect_url
      { :action => 'index' }
    end
    
end