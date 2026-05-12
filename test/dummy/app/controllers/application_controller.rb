class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  layout :application_layout

  before_action :authenticate_user!
  before_action :set_current_actor

  helper_method :current_workspace, :current_root_recording

  private

  def application_layout
    devise_controller? ? "application" : "flat_pack_sidebar"
  end

  def set_current_actor
    Current.actor = current_user
  end

  def current_workspace
    @current_workspace ||= Workspace.first
  end

  def current_root_recording
    @current_root_recording ||= RecordingStudio::Recording.unscoped.find_by(
      recordable: current_workspace,
      parent_recording_id: nil
    )
  end

  def authorize_recording_studio_categorisable!
    current_user.present?
  end
end
