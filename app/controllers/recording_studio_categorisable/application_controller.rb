# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    layout "recording_studio_categorisable/blank"
    helper_method :current_recording_studio_actor

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def ensure_authorized!(recording, role: nil)
      return true unless defined?(RecordingStudioAccessible)

      return true if RecordingStudioAccessible.authorized?(
        actor: current_recording_studio_actor,
        recording: recording,
        role: role || default_authorization_role
      )

      handle_forbidden_access
      false
    end

    def default_authorization_role
      %w[index show].include?(action_name.to_s) ? :view : :admin
    end

    def current_recording_studio_actor
      if defined?(Current) && Current.respond_to?(:actor)
        Current.actor
      elsif respond_to?(:current_user, true)
        current_user
      end
    end

    def current_root_recording
      @current_root_recording ||= configured_root_recording || requested_root_recording || default_root_recording
    end

    def configured_root_recording
      resolver = RecordingStudioCategorisable.configuration.root_recording_resolver
      resolver&.call(controller: self)
    end

    def requested_root_recording
      return unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording.find_by(id: params[:root_recording_id] || session[:root_recording_id])
    end

    def default_root_recording
      return unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording.find_by(parent_recording_id: nil)
    end

    def handle_forbidden_access
      if request.format.html?
        redirect_to(fallback_root_path, alert: "You are not allowed to access that page.")
      else
        head :forbidden
      end
    end

    def fallback_root_path
      main_app.root_path
    rescue StandardError
      "/"
    end

    def render_not_found
      if request.format.html?
        redirect_to fallback_root_path, alert: "Recording not found."
      else
        head :not_found
      end
    end
  end
end
