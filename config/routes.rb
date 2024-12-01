Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  namespace :api do
    namespace :v1 do
      resources :transactions
      resources :budgets
      resources :saving_goals
      resources :recurring_transactions
      
      # Analytics endpoints based on InsightsScreen
      get 'insights/overview', to: 'insights#overview'
      get 'insights/spending_by_category', to: 'insights#spending_by_category'
      get 'insights/weekly_trends', to: 'insights#weekly_trends'
    end
  end
  
  get "up" => "rails/health#show", as: :rails_health_check

end
