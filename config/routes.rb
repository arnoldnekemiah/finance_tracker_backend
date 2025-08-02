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
    end
  end
end
