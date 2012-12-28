class SchoolsController < ApplicationController
  include Roar::Rails::ControllerAdditions
  before_filter :authenticate_user!
  respond_to :json, :html

  def index
    @schools = School.order('id asc').all
    
    respond_to do |format|
      format.json { respond_with @schools }
    end
  end

  def show
    @school = School.find params[:id]
    respond_with @school
  end
end