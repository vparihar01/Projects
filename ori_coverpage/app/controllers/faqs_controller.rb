class FaqsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_tags, :only => [:index, :search, :tag]

  def index
    # @faqs = Faq.paginate(:page => params[:page], :per_page => pager)
    @faqs = Faq.all
  end
  
  def show
    @faq = Faq.find(params[:id])
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @faq.to_xml }
    end
  end
  
  def search
    # @faqs = Faq.where(["question like :q or answer like :q", {:q => "%#{params[:term]}%"}]).paginate( :page => params[:page], :per_page => pager)
    @faqs = Faq.where("question like :q or answer like :q", :q => "%#{params[:term]}%")
    render :index
  end
  
  def tag
    @page_title = "#{params[:tag].titlecase} - Faqs"
    # @faqs = Faq.paginate_tagged(params[:tag], :page => params[:page], :per_page => pager)
    @faqs = Faq.find_tagged_with(params[:tag])
    render :index
  end

  protected

    def load_tags
      @tags = Faq.tag_counts # returns all the tags used
    end
end
