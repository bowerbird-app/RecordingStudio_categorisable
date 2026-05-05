# frozen_string_literal: true

RecordingStudioCategorisable::Engine.routes.draw do
  root "home#index"

  resources :category_groups do
    resources :category_items, only: %i[show new create edit update destroy]
  end

  resources :target_recordings, path: "recordings", only: [] do
    resources :category_assignments, only: %i[index new create destroy]
  end
end
