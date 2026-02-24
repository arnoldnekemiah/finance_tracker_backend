Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Auth (public + authenticated)
      post   'auth/signup',          to: 'auth#signup'
      post   'auth/login',           to: 'auth#login'
      post   'auth/google',          to: 'auth#google'
      delete 'auth/logout',          to: 'auth#logout'
      get    'auth/me',              to: 'auth#me'
      post   'auth/forgot_password', to: 'auth#forgot_password'
      post   'auth/verify_otp',      to: 'auth#verify_otp'
      post   'auth/reset_password',  to: 'auth#reset_password'

      # CRUD Resources
      resources :accounts
      resources :categories
      resources :transactions do
        collection do
          get :stats
          get :spending_by_category
        end
      end
      resources :budgets do
        collection do
          get :active
          get :summary
        end
      end
      resources :debts
      resources :saving_goals

      # Dashboard & Insights
      get 'dashboard/overview',             to: 'dashboard#overview'
      get 'dashboard/financial_overview',   to: 'dashboard#financial_overview'
      get 'dashboard/spending_by_category', to: 'dashboard#spending_by_category'

      get 'insights/monthly_overview',      to: 'insights#monthly_overview'
      get 'insights/spending_by_category',  to: 'insights#spending_by_category'
      get 'insights/weekly_trends',         to: 'insights#weekly_trends'
      get 'insights/spending_comparison',   to: 'insights#spending_comparison'

      # Profile
      put    'profile',                to: 'profiles#update'
      post   'profile/upload_photo',   to: 'profiles#upload_photo'
      delete 'profile/delete_photo',   to: 'profiles#delete_photo'
      delete 'profile/delete_account', to: 'profiles#delete_account'

      # Support
      resources :support_messages, only: [:index, :create]

      # Data Reset
      post 'data/start_afresh',   to: 'data_reset#start_afresh'
      post 'data/delete_all',     to: 'data_reset#delete_all'
      post 'data/reset_balances', to: 'data_reset#reset_balances'
    end
  end

  # Admin routes
  namespace :admin do
    root 'dashboard#index'

    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    get 'validate_token', to: 'sessions#validate_token'

    post 'password_reset', to: 'password_resets#create'
    patch 'password_reset', to: 'password_resets#update'
    patch 'change_password', to: 'password_resets#change_password'

    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/health', to: 'dashboard#health_metrics'

    resources :users, only: [:index, :show, :update, :destroy] do
      member do
        patch :activate
        patch :deactivate
        patch :make_admin
        patch :remove_admin
      end
    end

    get 'analytics', to: 'analytics#index'
    namespace :analytics do
      get :user_growth
      get :transaction_volume
      get :financial_insights
      get :user_activity
      get :revenue_analytics
      get :export_data
    end

    get 'reports', to: 'reports#index'
    namespace :reports do
      post :generate_daily
      post :generate_weekly
      post :generate_monthly
      post :generate_custom
      get :schedule_reports
    end

    get 'settings', to: 'settings#index'
  end
end
