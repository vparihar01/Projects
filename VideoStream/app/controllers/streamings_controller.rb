class StreamingsController < ApplicationController
  # GET /streamings
  # GET /streamings.json
  def index
    @streamings = Streaming.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @streamings }
    end
  end

  def spreeui

  end

  def watch

  end

  def broadcast

  end

  def spree

  end

  # GET /streamings/1
  # GET /streamings/1.json
  def show
    @streaming = Streaming.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @streaming }
    end
  end

  # GET /streamings/new
  # GET /streamings/new.json
  def new
    @streaming = Streaming.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @streaming }
    end
  end

  # GET /streamings/1/edit
  def edit
    @streaming = Streaming.find(params[:id])
  end

  # POST /streamings
  # POST /streamings.json
  def create
    @streaming = Streaming.new(params[:streaming])

    respond_to do |format|
      if @streaming.save
        format.html { redirect_to @streaming, notice: 'Streaming was successfully created.' }
        format.json { render json: @streaming, status: :created, location: @streaming }
      else
        format.html { render action: "new" }
        format.json { render json: @streaming.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /streamings/1
  # PUT /streamings/1.json
  def update
    @streaming = Streaming.find(params[:id])

    respond_to do |format|
      if @streaming.update_attributes(params[:streaming])
        format.html { redirect_to @streaming, notice: 'Streaming was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @streaming.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /streamings/1
  # DELETE /streamings/1.json
  def destroy
    @streaming = Streaming.find(params[:id])
    @streaming.destroy

    respond_to do |format|
      format.html { redirect_to streamings_url }
      format.json { head :no_content }
    end
  end
end
