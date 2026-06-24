# frozen_string_literal: true

RecordingStudioCategorisable::Engine.routes.draw do
  root "home#index"

  resources :category_groups, except: %i[new create destroy] do
    resources :category_items, except: %i[index show]
  end
end
