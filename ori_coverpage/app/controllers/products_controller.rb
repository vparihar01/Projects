class ProductsController < ApplicationController
  skip_before_filter :login_required
  before_filter :load_product, :only => [:tooltip, :tooltipx]
  
  def index
    redirect_to shop_url
  end
  
  def show
    redirect_to show_url(params[:id])
  end

  def tooltip
    render_tooltip('tooltip')
  end
  
  def tooltipx
    render_tooltip('tooltipx')
  end
  
  protected

    def load_product
      @product = Product.find(params[:id])
    end

    def render_tooltip(partial)
      respond_to do |format|
        format.html { redirect_to show_path(@product) }
        format.js   {
          render(:partial => partial, :locals => {:product => @product})
        }
      end
    end

end
