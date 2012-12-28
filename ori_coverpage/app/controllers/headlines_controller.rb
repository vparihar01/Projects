class HeadlinesController < ApplicationController
  skip_before_filter :login_required
  before_filter :build_headline, :only => [:new, :create]
  before_filter :load_headline, :only => [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html { 
        @headlines = Headline.order('created_at DESC').paginate( :page => params[:page], :per_page => pager)
        render :layout => 'about' unless admin_scope?
      }
      format.xml  { 
        @headlines = Headline.order('created_at DESC')
        render :xml => @headlines.to_xml 
      }
    end
  end

  def show
    @page_title = "#{@headline.title} - Headlines"
    respond_to do |format|
      format.html { render :layout => 'about' } # show.rhtml
      format.xml  { render :xml => @headline.to_xml }
    end
  end
  
  protected
    
    def build_headline
      @headline = Headline.new(params[:headline])
    end
    
    def load_headline
      @headline = Headline.find(params[:id])
    end
  
end
