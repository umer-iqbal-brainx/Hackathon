Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "brief_workspaces#index"

  resources :brief_workspaces, only: %i[index show new create] do
    resources :brief_runs, only: %i[new create show] do
      member do
        get :export_csv
      end
    end
  end
end
