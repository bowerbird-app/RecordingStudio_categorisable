# frozen_string_literal: true

RecordingStudioCategorisable::Engine.routes.draw do
  root "categories#index"
  get "new", to: "categories#new", as: :new_category
  post "/", to: "categories#create", as: :categories
  get "recordings/:recording_id/category/edit", to: "category_choices#edit", as: :edit_recording_category
  patch "recordings/:recording_id/category", to: "category_choices#update", as: :recording_category
  delete "recordings/:recording_id/category", to: "category_choices#destroy"
  get ":id/recordings", to: "filters#show", as: :category_recordings
end
