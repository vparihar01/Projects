Coverpage::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  #gem 'metric_fu', :require => 'metric_fu'

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  # yes, we do care because we want to develop software that works 100%
  # TODO: uncomment the line below if want to turn this off, however
  #config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # old settings

  config.colorize_logging = false

  config.after_initialize do
    # ActiveMerchant::Billing::Base.gateway_mode = :test
    # Override MiniCaptcha defaults
    MiniCaptcha.image_dir = "tmp"
    MiniCaptcha.image_format = "jpeg"
    MiniCaptcha.token_length = 4
    MiniCaptcha.image_distort = "charcoal wave(20,160)"
    MiniCaptcha.token_charset = "23456789abcdefghijkmnpqrstuvwxyz"
  end

end




