CarrierWave.configure do |config|
  # if Rails.env == "development"
  #   config.fog_credentials = {
  #     :provider => "local",
  #     :local_root => Rails.root
  #   }
  #   config.fog_directory  = "public"
  # end


  if Rails.env == "development" || Rails.env == "dreamhost"
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => 'AKIAJ4I3I4QU6YNY2RDQ',
      :aws_secret_access_key  => '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',
      :region                 => 'us-east-1'
    }
    config.fog_directory  = "sportsbeatdev"
  end
end