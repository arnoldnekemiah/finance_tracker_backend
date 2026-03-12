require "active_support/core_ext/integer/time"
require_relative "../app_url"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  app_url_options = AppUrl.admin_url_options

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable serving static files from the `/public` folder.
  # Required when running behind Nginx which proxies to Puma (Puma doesn't
  # serve static files itself in this setup).
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = app_url_options[:protocol] == 'https'

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Disabled: running on raw IP without SSL termination
  config.force_ssl = false

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "finance_tracker_api_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = app_url_options

  config.after_initialize do
    Rails.application.routes.default_url_options = app_url_options
  end

  if ENV['BREVO_SMTP_PASSWORD'].present?
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              'smtp-relay.brevo.com',
      port:                 587,
      domain:               ENV.fetch('BREVO_DOMAIN', 'ikondesoft.com'),
      user_name:            ENV.fetch('BREVO_SMTP_USERNAME', ENV['BREVO_USERNAME']),
      password:             ENV['BREVO_SMTP_PASSWORD'],
      authentication:       'plain',
      enable_starttls_auto: true
    }
  elsif ENV['MAILTRAP_USERNAME'].present?
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              'live.smtp.mailtrap.io',
      port:                 587,
      domain:               'mailtrap.io',
      user_name:            ENV['MAILTRAP_USERNAME'],
      password:             ENV['MAILTRAP_PASSWORD'],
      authentication:       'plain',
      enable_starttls_auto: true
    }
  else
    # No SMTP credentials configured — log emails instead of sending.
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.delivery_method = :logger
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    "api.ikondesoft.com",            # API host
    "admin.ikondesoft.com",          # Admin host
    /.*\.ikondesoft\.com/            # Allow all ikondesoft.com subdomains
  ]
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.action_dispatch.trusted_proxies = ['127.0.0.1', '::1']
end
