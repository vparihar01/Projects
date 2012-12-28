class Admin::SalesController < AdminController
  include AdminModelControllerMethods
    
  verify :only => :set_status, :method => :post, 
         :params => 'status', :redirect_to => { :action => 'index' }
           
  def index
    @sales = Sale.order('completed_at DESC').all # Override AdminModelControllerMethods
  end
  
  def set_status
    load_object # Use AdminModelControllerMethods to load @sale
    begin
      @sale.update_attribute(:status, params[:status])
      flash[:notice] = "The status has been updated."
    rescue => e
      flash[:error] = e.message
    end
    redirect_to admin_sale_url(@sale)
  end
  
end
