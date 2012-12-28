class UsersController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    if user_signed_in?
      redirect_to user_path current_user
    else
      not_found
    end
  end

  def show
    user = User.find params[:id]
    user.extend UserRepresenter

    respond_to do |format|
      format.html { render :show, :locals => {:user => user} }
      format.json { render :json => user }
    end
  end
end