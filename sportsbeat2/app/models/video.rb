class Video < ActiveRecord::Base
  mount_uploader :file, VideoUploader

  belongs_to :owner, :class_name => "User"

  validates_presence_of :file
 
  def processed!
    update_attribute(:processed, true)
  end

  # returns percentage completion of the 
  def progress
    if processed
      return 100.0
    end

    response = Zencoder::Job.progress(zencoder_job_id)
    
    if response.body["state"] == "finished"
      processed!
      return 100.0
    end

    return response.body["progress"] if response.body["progress"]

    return 0.0
  end

  def thumbnail_url
    File.dirname(file.url) + "/frame_0000.jpg"
  end
end