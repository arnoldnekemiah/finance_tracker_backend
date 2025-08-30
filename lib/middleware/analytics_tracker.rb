module Middleware
  class AnalyticsTracker
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      
      # Track the request
      track_request(request) if should_track?(request)
      
      @app.call(env)
    end

    private

    def should_track?(request)
      # Only track authenticated requests to avoid noise
      return false unless request.headers['Authorization'].present?
      
      # Skip tracking for admin endpoints to avoid recursive tracking
      return false if request.path.start_with?('/admin/analytics')
      
      # Track API endpoints
      request.path.start_with?('/api/') || request.path.start_with?('/admin/')
    end

    def track_request(request)
      # Extract user from JWT token if present
      user = extract_user_from_token(request)
      return unless user

      event_type = determine_event_type(request)
      return unless event_type

      UserAnalytics.track_event(
        user,
        event_type,
        {
          path: request.path,
          method: request.method,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          params: sanitize_params(request.params)
        }
      )
    rescue => e
      Rails.logger.error "Analytics tracking failed: #{e.message}"
    end

    def extract_user_from_token(request)
      auth_header = request.headers['Authorization']
      return nil unless auth_header&.start_with?('Bearer ')

      token = auth_header.split(' ').last
      decoded_token = JWT.decode(
        token,
        Rails.application.credentials.devise_jwt_secret_key,
        true,
        { algorithm: 'HS256' }
      )
      
      # Match the application controller's JWT claim key
      user_id = decoded_token.first['sub']
      User.find_by(id: user_id)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    def determine_event_type(request)
      path = request.path
      method = request.method

      case path
      when %r{^/api/v1/transactions}
        case method
        when 'POST' then 'transaction_created'
        when 'PUT', 'PATCH' then 'transaction_updated'
        when 'DELETE' then 'transaction_deleted'
        end
      when %r{^/api/v1/budgets}
        case method
        when 'POST' then 'budget_created'
        when 'PUT', 'PATCH' then 'budget_updated'
        end
      when %r{^/api/v1/accounts}
        case method
        when 'POST' then 'account_created'
        end
      when %r{^/api/v1/saving_goals}
        case method
        when 'POST' then 'saving_goal_created'
        end
      when %r{^/api/v1/debts}
        case method
        when 'POST' then 'debt_created'
        end
      when %r{^/api/v1/profile}
        case method
        when 'PUT', 'PATCH' then 'profile_updated'
        end
      when %r{^/login}
        'login' if method == 'POST'
      when %r{^/logout}
        'logout' if method == 'DELETE'
      when %r{^/admin/}
        "admin_#{method.downcase}_#{path.split('/').last}"
      end
    end

    def sanitize_params(params)
      # Remove sensitive information from params
      sanitized = params.except('password', 'password_confirmation', 'current_password')
      sanitized.to_h.slice(*%w[controller action id])
    end
  end
end