class ZencoderCallbackController < ApplicationController
  skip_before_filter :verify_authenticity_token
 
  def create
    output_id = params[:output][:id]
    job_state = params[:job][:state]
    # thumbnails = params[:output][:thumbnail]
 
    video = Video.find_by_zencoder_output_id(output_id)

    Video.transaction do
      if job_state == "finished" && video
        video.processed!
      end

      # if thumbnail
      #   video.thumbnail_url = thumbnails[0][:images][0][:url]
      # end

      video.save
    end
 
    render :nothing => true
  end
end