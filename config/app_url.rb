module AppUrl
  module_function

  def admin_host(env = ENV)
    preferred_host(env, 'ADMIN_APP_HOST', fallback_key: 'APP_HOST', default: 'admin.ikondesoft.com')
  end

  def api_host(env = ENV)
    preferred_host(env, 'API_APP_HOST', default: 'api.ikondesoft.com')
  end

  def protocol(env = ENV)
    env.fetch('APP_PROTOCOL', 'https')
  end

  def admin_url_options(env = ENV)
    {
      host: admin_host(env),
      protocol: protocol(env)
    }
  end

  def admin_base_url(env = ENV)
    "#{protocol(env)}://#{admin_host(env)}"
  end

  def api_base_url(env = ENV)
    "#{protocol(env)}://#{api_host(env)}"
  end

  def swagger_servers(env = ENV)
    [
      {
        url: 'http://localhost:3000',
        description: 'Local development (localhost)'
      },
      {
        url: 'http://127.0.0.1:3000',
        description: 'Local development (127.0.0.1)'
      },
      {
        url: api_base_url(env),
        description: "Production API (#{api_host(env)})"
      }
    ]
  end

  def preferred_host(env, key, fallback_key: nil, default:)
    value = env[key]
    value = env[fallback_key] if value.to_s.empty? && fallback_key
    value.to_s.empty? ? default : value
  end
end
