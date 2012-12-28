if Rails.env == "development" || Rails.env == "dreamhost"
  $redis = Redis.new(:host => 'localhost', :port => 6379)
end