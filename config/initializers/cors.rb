# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Be sure to restart your server when you modify this file.
# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # In development, allow requests from localhost:3001 (or your frontend port)
      origins 'http://localhost:3001', 'http://127.0.0.1:3001'
    else
      # In production, replace with your frontend URL
      # Example: 'https://your-frontend-domain.com'
      origins '*'
    end

    resource '*',
      headers: %w[Authorization Content-Type X-User-Token X-User-Email X-CSRF-Token],
      expose: ['access-token', 'expiry', 'token-type', 'uid', 'client'],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 0
  end
end
