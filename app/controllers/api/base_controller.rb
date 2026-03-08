class Api::BaseController < ApplicationController
  # Disable CSRF protection for JSON API endpoints.
  # Authentication is handled via JWT Bearer tokens instead.
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token

  # Disable Rails' automatic parameter wrapping (which nests params under a
  # controller-name key, e.g. { auth: { email: ... } } for AuthController).
  # API clients send flat JSON bodies and expect them to remain flat.
  wrap_parameters false
end
