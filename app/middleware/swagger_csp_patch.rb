# Rswag::Ui embeds a restrictive Content-Security-Policy on /api-docs pages.
# The CSP's `default-src 'self'` blocks browser fetch() calls when the Swagger
# UI page origin (e.g. http://127.0.0.1:3000) differs from the server URL in
# swagger.yaml (e.g. http://localhost:3000), because browsers treat those as
# different origins and the CSP blocks the request before it's even sent.
#
# This middleware removes the CSP from /api-docs responses so that Swagger UI
# can call any server URL listed in the spec without browser interference.
class SwaggerCspPatch
  def initialize(app)
    @app = app
  end

  def call(env)
    # Capture PATH_INFO before calling the inner app: Rails' router mutates it
    # when dispatching to a mounted engine (e.g. it becomes /index.html after
    # Rswag::Ui::Engine strips the /api-docs prefix).
    path = env['PATH_INFO']

    status, headers, body = @app.call(env)

    if path&.start_with?('/api-docs')
      # Return a new headers hash without the Content-Security-Policy that
      # Rswag::Ui injects. That CSP has `default-src 'self'` which blocks
      # fetch() requests when the Swagger page origin (e.g. 127.0.0.1:3000)
      # differs from the server URL in swagger.yaml (e.g. localhost:3000).
      return [status, headers.to_h.reject { |k, _| k.downcase == 'content-security-policy' }, body]
    end

    [status, headers, body]
  end
end
