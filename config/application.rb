require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FinanceTrackerApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Enable views for admin interface while keeping API functionality
    # We'll use both API and web views for the admin panel
    config.api_only = false
    
    # Require and add custom analytics tracking middleware
    require Rails.root.join('lib/middleware/analytics_tracker')
    config.middleware.use AnalyticsTracker

    # Add back cookies and session middleware for JWT
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: '_finance_tracker_session', same_site: :lax, secure: Rails.env.production?

    # Initialize JWT configuration
    config.to_prepare do
      Devise.setup do |config|
        config.navigational_formats = []
      end
    end
  end
end
