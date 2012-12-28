class TestimonialsController < ApplicationController
  skip_before_filter :login_required

  def index
    respond_to do |format|
      format.html { 
        @testimonials = Testimonial.order('created_at DESC').paginate( :page => params[:page], :per_page => pager)
      }
      format.xml  { 
        @testimonials = Testimonial.order( 'created_at DESC' )
        render :xml => @testimonials.to_xml 
      }
    end
  end

  def show
    @testimonial = Testimonial.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @testimonial.to_xml }
    end

  rescue Exception => e
    flash[:error] = 'Error finding testimonial'.concat(" (#{e.message})")
    redirect_to testimonials_url and return
  end

end
