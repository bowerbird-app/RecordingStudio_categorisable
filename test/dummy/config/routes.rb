Rails.application.routes.draw do
  devise_for :users

  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioCategorisable::Engine, at: "/categories"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :projects, only: [:index, :show]
  root "projects#index"
end
