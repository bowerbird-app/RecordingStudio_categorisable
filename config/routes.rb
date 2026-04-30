# frozen_string_literal: true

RecordingStudioCategorisable::Engine.routes.draw do
  root "home#index"

  resources :category_groups do
    resources :category_items
  end

  # Nested under any recording (via target_recording_id parameter)
  scope "recordings/:target_recording_id" do
    resources :category_assignments, only: [:index, :new, :create, :destroy]
  end
end
