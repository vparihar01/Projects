# encoding: utf-8

class VideoUploader < CarrierWave::Uploader::Base
  # used to get the value of zencoder_callback_url
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options = ActionMailer::Base.default_url_options

  # Choose what kind of storage to use for this uploader:
  storage :fog

  after :store, :zencode

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  def extension_white_list
    %w(avi flv mkv mov mp4 mpg wmv)
  end

  def filename
    if original_filename
      ext = File.extname(original_filename)
      return original_filename.chomp(ext) + ".mp4"
    end

    super
  end
  
  def zencode args
    options = {
      :input => model.file.url,
      :output => {
        :url => model.file.url,
        :notifications => [zencoder_callback_url(:protocol => "http")],
        :format => "mp4",
        :public => 1,
        :thumbnails => {
          :number => 1,
          :format => :jpg,
          :base_url => File.dirname(model.file.url)
        },
        :watermarks => {
          :url => "s3://sportsbeat/sbicon.png",
          :y => "-0",
          :x => "-0",
          :width => "24",
          :height => "24"
        }
      },

    }

    zencoder_response = Zencoder::Job.create(options)

    if zencoder_response.errors.length > 0
      raise "There was a zencoder error"
    else
      model.zencoder_job_id = zencoder_response.body["id"]

      zencoder_response.body["outputs"].each do |output|
        model.zencoder_output_id = output["id"]
        model.processed = false
        model.save(:validate => false)
      end
    end
  end

end
