if Rails.env == "development"
  Tire::Configuration.url("http://localhost:9200")
end