# Load mail configuration if not in test environment
unless Rails.env.test?
  MAILER = YAML.load_file(Rails.root.join("config", "mailer.yml"))
  ActionMailer::Base.smtp_settings = MAILER[Rails.env] unless MAILER[Rails.env].nil?
end
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
