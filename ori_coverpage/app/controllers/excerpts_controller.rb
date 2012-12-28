class ExcerptsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_excerpt, :only => [:click, :read]
  before_filter :init_cart

  def index
    @page_title = "Samples"
    @excerpts = Excerpt.includes(:title).order('products.name ASC').paginate( :page => params[:page], :per_page => pager)
  end
  
  def click
    send_file(@excerpt.full_filename, :x_sendfile => CONFIG[:use_xsendfile])
  end

  def read
    @page_title = "#{@excerpt.title.name} - Excerpts"
    render :layout => 'blank'
  end
  
  protected
    
    def load_excerpt
      begin
    		@excerpt = Excerpt.find(params[:id])
    	rescue
  			flash[:error] = "Unknown ID"
  			redirect_to excerpts_url
    	end
    end
end
