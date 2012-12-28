class SportsController < ApplicationController
  include Roar::Rails::ControllerAdditions
  before_filter :authenticate_user!
  respond_to :json

  def index
    sports = Sport.order('name asc').all
    respond_with sports
  end

  def positions
    sport = Sport.find params[:id]
    respond_with sport, :represent_with => SportPositionsRepresenter
  end

  def show
    sport = Sport.find params[:id]
    respond_with sport
  end
end