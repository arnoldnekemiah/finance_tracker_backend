require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module FinanceTrackerApi
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    # Keep both API and web views for admin panel
    config.api_only = false

    # Cookies and session for admin panel
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: '_accountanta_session', same_site: :lax, secure: Rails.env.production?

    # Devise navigational formats
    config.to_prepare do
      Devise.setup do |config|
        config.navigational_formats = []
      end
    end
  end
end
