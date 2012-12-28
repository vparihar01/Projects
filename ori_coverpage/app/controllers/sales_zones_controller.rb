class SalesZonesController < ApplicationController
  before_filter :load_sales_zone, :only => [ :show, :edit, :update, :destroy ]
  before_filter :new_sales_zone, :only => [ :new, :create ]
  layout 'sales'

  def index
    @sales_zones = SalesZone.order("sales_zones.name ASC").paginate(:page => params[:page], :per_page => pager)
  end
  
  def show
    @page_title = "#{@sales_zone.name} - Sales Zones"
    @contracts = current_user.admin? ? @sales_zone.contracts : 
      @sales_zone.contracts.select {|c| c.sales_team == current_user.sales_team }
  end
  
  protected
  
    def load_sales_zone
      @sales_zone = SalesZone.find(params[:id])
    end
    
    def new_sales_zone
      @sales_zone = SalesZone.new(params[:sales_zone])
    end
  
    def authorized?
      return false if current_user.customer?
      current_user.admin? || %w(show).include?(self.action_name)
    end
end
