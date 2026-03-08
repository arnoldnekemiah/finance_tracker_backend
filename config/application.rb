require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

# Load custom Rack middleware before the middleware stack is built.
require_relative "../app/middleware/swagger_csp_patch"

module FinanceTrackerApi
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    # Keep both API and web views for admin panel
    config.api_only = false

    # Cookies and session for admin panel.
    # Use config.session_store to configure the existing middleware rather than
    # adding a duplicate via config.middleware.use.
    config.session_store :cookie_store,
      key: '_accountanta_session',
      same_site: :lax,
      secure: Rails.env.production?

    # Rswag::Ui injects a restrictive Content-Security-Policy on /api-docs pages
    # that blocks browser fetch() calls when the page origin (e.g. 127.0.0.1)
    # differs from the swagger.yaml server URL (e.g. localhost). Strip that CSP
    # so Swagger UI can reach the API regardless of how the app is accessed.
    config.middleware.use SwaggerCspPatch

    # Devise navigational formats
    config.to_prepare do
      Devise.setup do |config|
        config.navigational_formats = []
      end
    end
  end
end
