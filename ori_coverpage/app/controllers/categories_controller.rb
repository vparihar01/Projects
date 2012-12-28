class CategoriesController < ApplicationController
  skip_before_filter :login_required
  before_filter :init_cart, :store_location

  def index
    @page_title = "Subjects"
    @categories = Category.visible.order("name")
  end

  def show
    @category = Category.visible.find(params[:id])
    @page_title = "#{@category.name} - Subjects"
    @products = @category.products.available.active.grade( params[:grade] ).paginate( :order => "name", :page => params[:page], :per_page => pager )
    respond_to do |format|
      format.html {}
      format.xml  { render :xml => @category.to_xml }
    end
  end

end
