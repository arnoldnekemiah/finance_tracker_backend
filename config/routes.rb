Rails.application.routes.draw do
  mount Rswag::Ui::Engine  => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

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
      post 'data/start_afresh',       to: 'data_reset#start_afresh'
      post 'data/delete_all',         to: 'data_reset#delete_all'
      post 'data/reset_balances',     to: 'data_reset#reset_balances'
      post 'data/reconcile_balances', to: 'data_reset#reconcile_balances'

      # Exchange rates (proxied for frontend)
      get 'exchange_rates', to: 'exchange_rates#index'

      # Extended insights
      get 'insights/monthly_trends',  to: 'insights#monthly_trends'
      get 'insights/income_vs_expense', to: 'insights#income_vs_expense'
    end
  end

  # Admin routes - accessible via admin subdomain
  constraints subdomain: 'admin' do
    scope module: :admin, as: :subdomain_admin do
      root 'dashboard#index'
      get 'login', to: 'sessions#new'
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'
      get 'validate_token', to: 'sessions#validate_token'
      
      # Password reset (OTP-based)
      post 'password_reset', to: 'password_resets#create'
      patch 'password_reset', to: 'password_resets#update'
      patch 'change_password', to: 'password_resets#change_password'
      post 'send_reset_otp', to: 'sessions#send_reset_otp', as: :send_reset_otp
      post 'verify_reset_otp', to: 'sessions#verify_reset_otp', as: :verify_reset_otp
      get 'reset_password', to: 'sessions#forgot_password', as: :reset_password
      post 'reset_password', to: 'sessions#reset_password'
      
      # Dashboard
      get 'dashboard', to: 'dashboard#index'
      get 'dashboard/health', to: 'dashboard#health_metrics'
      
      # User management
      resources :users, only: [:index, :show, :update, :destroy] do
        member do
          patch :activate
          patch :deactivate
          patch :make_admin
          patch :remove_admin
        end
      end
      
      # Admin invitations
      resources :invitations, only: [:index, :create, :destroy]
      get 'invitations/:token/accept', to: 'invitations#show', as: :accept_invitation
      post 'invitations/:token/accept', to: 'invitations#accept', as: :process_invitation
      
      # Audit logs
      resources :audit_logs, only: [:index]
      
      # Analytics
      get 'analytics', to: 'analytics#index'
      namespace :analytics do
        get :user_growth
        get :transaction_volume
        get :financial_insights
        get :user_activity
        get :revenue_analytics
        get :export_data
      end
      
      # Reports
      get 'reports', to: 'reports#index'
      namespace :reports do
        post :generate_daily
        post :generate_weekly
        post :generate_monthly
        post :generate_custom
        get :schedule_reports
      end
      
      # Settings
      get 'settings', to: 'settings#index'
    end
  end

  # Admin routes via /admin path (for backward compatibility)
  namespace :admin do
    root 'dashboard#index'

    # Authentication
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    get 'validate_token', to: 'sessions#validate_token'

    # Password reset (OTP-based)
    post 'password_reset', to: 'password_resets#create'
    patch 'password_reset', to: 'password_resets#update'
    patch 'change_password', to: 'password_resets#change_password'
    post 'send_reset_otp', to: 'sessions#send_reset_otp', as: :send_reset_otp
    post 'verify_reset_otp', to: 'sessions#verify_reset_otp', as: :verify_reset_otp
    get 'reset_password', to: 'sessions#forgot_password', as: :reset_password
    post 'reset_password', to: 'sessions#reset_password'

    # Dashboard
    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/health', to: 'dashboard#health_metrics'

    # User management
    resources :users, only: [:index, :show, :update, :destroy] do
      member do
        patch :activate
        patch :deactivate
        patch :make_admin
        patch :remove_admin
      end
    end

    # Admin invitations
    resources :invitations, only: [:index, :create, :destroy]
    get 'invitations/:token/accept', to: 'invitations#show', as: :accept_invitation
    post 'invitations/:token/accept', to: 'invitations#accept', as: :process_invitation

    # Audit logs
    resources :audit_logs, only: [:index]

    # Analytics
    get 'analytics', to: 'analytics#index'
    namespace :analytics do
      get :user_growth
      get :transaction_volume
      get :financial_insights
      get :user_activity
      get :revenue_analytics
      get :export_data
    end

    # Reports
    get 'reports', to: 'reports#index'
    namespace :reports do
      post :generate_daily
      post :generate_weekly
      post :generate_monthly
      post :generate_custom
      get :schedule_reports
    end

    # Settings
    get 'settings', to: 'settings#index'
  end
end
