Rails.application.routes.draw do
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"
  mount RecordingStudioAccessible::Engine, at: "/recording_studio_accessible" if defined?(RecordingStudioAccessible::Engine)
  mount RecordingStudioCategorisable::Engine, at: "/recording_studio_categorisable"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get "install", to: "guides#install"
  get "config", to: "guides#configuration"
  get "methods", to: "guides#methods"
  get "components", to: "guides#components"
  get "recording-tree", to: "guides#recording_tree"

  resources :pages, only: %i[index new create edit update]
  resources :briefs, only: %i[index new create edit update]
  root "home#index"
end
