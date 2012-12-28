class Admin::TestimonialsController < AdminController
  before_filter :build_testimonial, :only => [:new, :create]
  before_filter :load_testimonial, :only => [:show, :edit, :update, :destroy]

  def index
    @search = Testimonial.search(params[:search])

    respond_to do |format|
      format.html {
        @testimonials = @search.paginate(:page => params[:page], :per_page => pager)
      }
      format.xml  {
        @testimonials = @search.all
        render :xml => @testimonials.to_xml
      }
    end
  end

  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @testimonial.to_xml }
    end
  end

  def create
    respond_to do |format|
      if @testimonial.save
        flash[:notice] = 'Testimonial was successfully created.'
        format.html { redirect_to admin_testimonials_url }
        format.xml  { head :created, :location => admin_testimonials_url }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @testimonial.errors.to_xml }
      end
    end
  end
  
  def edit
    # refs #359
  end

  def update
    respond_to do |format|
      if @testimonial.update_attributes(params[:testimonial])
        flash[:notice] = 'Testimonial was successfully updated.'
        format.html { redirect_to admin_testimonials_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @testimonial.errors.to_xml }
      end
    end
  end

  def destroy
    @testimonial.destroy
    respond_to do |format|
      flash[:notice] = 'Testimonial was successfully deleted.'
      format.html { redirect_to admin_testimonials_url }
      format.xml  { head :ok }
    end
  end

  protected

    def build_testimonial
      @testimonial = Testimonial.new(params[:testimonial])
    end

    def load_testimonial
      @testimonial = Testimonial.find(params[:id])
    rescue Exception => e
      flash[:error] = 'Error finding testimonial'.concat(" (#{e.message})")
      redirect_to admin_testimonials_url and return
    end

end
