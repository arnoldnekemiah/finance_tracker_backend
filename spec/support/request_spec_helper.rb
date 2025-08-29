require 'devise/jwt/test_helpers'

module RequestSpecHelper
  def auth_headers_for(user)
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    Devise::JWT::TestHelpers.auth_headers(headers, user)
  end
end
