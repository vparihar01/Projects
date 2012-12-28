class LevelsController < ApplicationController
  skip_before_filter :login_required
  before_filter :init_cart, :store_location

  def index
    @page_title = "Levels"
    @levels = Level.visible
  end

  def show
    @level = Level.visible.find_by_abbreviation(params[:id])
    raise ActiveRecord::RecordNotFound, "Couldn't find Level with abbreviation #{params[:id]}" unless @level
    @page_title = "#{@level.name} - Levels"
    if !params[:category_id].blank? && category = Category.find(params[:category_id])
      @products = category.products.join_formats_with_distinct.available.active.grade(@level.value).order('name ASC').paginate(:page => params[:page], :per_page => pager)
    else
      @products = Assembly.join_formats_with_distinct.available.active.grade(@level.value).order('name ASC').paginate(:page => params[:page], :per_page => pager)
    end
  end

end
