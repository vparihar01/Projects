class GamesController < ApplicationController
  include Roar::Rails::ControllerAdditions
  before_filter :authenticate_user!
  respond_to :json
  
  def show
    game = Game.find params[:id]
    respond_to do |format|
      format.html { render :show, :locals => {:game => game} }
      format.json { respond_with game, :represent_with => ExtendedGameRepresenter }
    end
  end
end