# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    layout "recording_studio_categorisable/blank"
    helper_method :current_recording_studio_actor

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def authorize_action!(recording, role: nil)
      return true unless defined?(RecordingStudioAccessible)

      allowed = RecordingStudioAccessible.authorized?(
        actor: current_recording_studio_actor,
        recording: recording,
        role: role || default_authorization_role
      )
      return true if allowed

      if request.format.html?
        redirect_to(fallback_root_path, alert: "You are not allowed to access that page.")
      else
        head :forbidden
      end
      false
    end

    def default_authorization_role
      case action_name.to_s
      when "index", "show"
        :view
      else
        :admin
      end
    end

    def current_recording_studio_actor
      if defined?(Current) && Current.respond_to?(:actor)
        Current.actor
      elsif respond_to?(:current_user, true)
        current_user
      end
    end

    def current_root_recording
      @current_root_recording ||= begin
        resolver = RecordingStudioCategorisable.configuration.root_recording_resolver
        resolved = resolver&.call(controller: self)
        resolved ||= RecordingStudio::Recording.find_by(id: params[:root_recording_id] || session[:root_recording_id]) if defined?(RecordingStudio::Recording)
        resolved ||= RecordingStudio::Recording.find_by(parent_recording_id: nil) if defined?(RecordingStudio::Recording)
        resolved
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
