module PublicModelControllerMethods
  def self.included(base)
    base.send :before_filter, :load_object, :only => [ :show ]
  end
  
  def index
    self.instance_variable_set('@' + self.controller_name,
      scoper.order('name').paginate( :page => params[:page], :per_page => pager) )
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