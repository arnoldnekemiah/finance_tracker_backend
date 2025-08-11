Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # API routes
  namespace :api do
    namespace :v1 do
      # Transaction routes
      resources :transactions, only: [:index, :create, :show, :update, :destroy]
      
      # Debt routes (replaces recurring transactions)
      resources :debts, only: [:index, :create, :show, :update, :destroy] do
        member do
          patch :mark_as_paid
        end
      end
      
      # Account routes
      resources :accounts, only: [:index, :create, :show, :update, :destroy] do
        member do
          patch :update_balance
        end
      end
      
      # Budget routes
      resources :budgets, only: [:index, :create, :show, :update, :destroy]
      
      # Saving goals routes
      resources :saving_goals, only: [:index, :create, :show, :update, :destroy] do
        member do
          patch :update_progress
        end
      end
      
      # Category routes
      resources :categories, only: [:index, :create, :show, :update, :destroy]
      
      # Dashboard routes
      get 'dashboard', to: 'dashboard#index'
      get 'dashboard/financial_overview', to: 'dashboard#financial_overview'
      get 'dashboard/monthly_summary', to: 'dashboard#monthly_summary_by_month'
      
      # Currency routes
      get 'currencies', to: 'currencies#index'
      patch 'currencies/preference', to: 'currencies#update_preference'
      get 'currencies/exchange_rates', to: 'currencies#exchange_rates'

      # Profile routes
      resource :profile, only: [:show, :update] do
        get :dashboard_summary
      end

      # Insights routes
      namespace :insights do
        get :overview
        get :spending_by_category
        get :spending_comparison
        get :weekly_trends
end

      # Reports routes
      namespace :reports do
        get :monthly_comparison
        get :spending_by_category
      end
      
      # Password reset routes
      post 'password_reset', to: 'password_resets#create'
      patch 'password_reset', to: 'password_resets#update'
    end
  end

  # Admin routes
  namespace :admin do
    # Root route for admin
    root 'dashboard#index'
    
    # Admin authentication
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    get 'validate_token', to: 'sessions#validate_token'
    
    # Password reset
    post 'password_reset', to: 'password_resets#create'
    patch 'password_reset', to: 'password_resets#update'
    patch 'change_password', to: 'password_resets#change_password'
    
    # Admin dashboard
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
