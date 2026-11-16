# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Sign-in keeps its own layout. Every other screen uses the Recording Studio layout.
  recording_studio_layout { devise_controller? ? "application" : nil }

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_actor

  private

  def set_current_actor
    Current.actor = current_user
  end
end
