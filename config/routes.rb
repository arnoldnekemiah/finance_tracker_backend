Rails.application.routes.draw do
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
      resources :transactions
      resources :recurring_transactions
      resources :budgets
      resources :saving_goals

      # Insights routes
      scope :insights do
        get 'overview', to: 'insights#overview'
        get 'spending_by_category', to: 'insights#spending_by_category'
        get 'weekly_trends', to: 'insights#weekly_trends'
      end
    end
  end
end
