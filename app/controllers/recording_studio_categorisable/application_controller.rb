# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout "blank"

    private

    def authorize_action!(recording)
      return true unless defined?(RecordingStudioAccessible)

      policy = RecordingStudioAccessible::Policy.new(Current.actor, recording)
      raise RecordingStudioAccessible::AccessDeniedError unless policy.public_send("#{action_name}?")
    end

    def current_workspace_recording
      @current_workspace_recording ||= RecordingStudio::Recording.find_by(
        recordable_type: "Workspace",
        recordable_id: workspace_id
      )
    end

    def workspace_id
      # In production, this would come from session/params
      # For now, we'll find the first workspace
      @workspace_id ||= Workspace.first&.id
    end
  end
end
