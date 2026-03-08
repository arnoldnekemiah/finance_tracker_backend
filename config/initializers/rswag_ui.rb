Rswag::Ui.configure do |c|
  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'Finance Tracker API V1'

  # Allow Swagger UI to send the Authorization header without CSRF issues.
  # This config key disables the "Try it out" CSRF enforcement in rswag.
  c.config_object['persistAuthorization'] = true
end
