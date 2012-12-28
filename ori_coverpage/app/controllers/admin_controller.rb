class AdminController < ApplicationController
  skip_before_filter :login_required
  before_filter :admin_required
  layout 'admin'
  
  def show
    @force_active = :home
    @page_title = "Admin"
  end

end
