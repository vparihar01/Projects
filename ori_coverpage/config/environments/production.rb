Coverpage::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # ERROR: "hostname was not match with the server certificate"
  # current solution: http://scottiestech.info/2009/12/21/fixing-the-actionmailer-hostname-not-match-server-certificate-error/
  #config.action_mailer.smtp_settings = {:enable_starttls_auto => false} # TODO: need better fix <-- THIS LINE HAS BEEN MOVED TO config/email.yml to the SMTP configuration part, this comment block shou
  # TODO: deprecate the above comment block when cleaning up

  config.after_initialize do
    # Override MiniCaptcha defaults
    MiniCaptcha.token_length = 4
  end

  # exception notification
  config.middleware.use ::ExceptionNotifier,
    :email_prefix => "[#{CONFIG[:app_name]}] ",
    :sender_address => %{"Exception Notifier" <#{CONFIG[:webmaster_email]}>},
    :exception_recipients => %W(#{CONFIG[:exception_email]} #{CONFIG[:webmaster_email]}),
    :sections => %w(request session environment backtrace)

end
