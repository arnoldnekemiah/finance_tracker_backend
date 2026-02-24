source "https://rubygems.org"

ruby "3.4.5"

# Core
gem "rails", "~> 7.1.5"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Authentication
gem 'devise'
gem 'devise-jwt'
gem "bcrypt", "~> 3.1.7"
gem 'jwt'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'

# CORS
gem 'rack-cors'

# Serialization
gem 'active_model_serializers'

# Pagination
gem 'kaminari'

# Image Processing
gem "image_processing", "~> 1.2"

# Windows timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Boot speed
gem "bootsnap", require: false

group :development, :test do
  gem 'rspec-rails', '~> 7.0.0'
  gem 'factory_bot_rails'
  gem 'faker'
  gem "debug", platforms: %i[ mri windows ]
  gem 'letter_opener'
end

group :development do
  # gem "spring"
end
