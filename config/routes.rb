# frozen_string_literal: true

RecordingStudioCategorisable::Engine.routes.draw do
  root "home#index"

  resources :category_groups do
    resources :category_items, except: :index
  end
end
