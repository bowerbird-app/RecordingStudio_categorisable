# frozen_string_literal: true

module RecordingStudioCategorisable
  class NotAllowed < StandardError; end

  # Accessible is the only grant check. When the host has not loaded it,
  # Core's authorize_write remains the write gate.
  module Access
    module_function

    def allowed?(actor:, recording:, role:)
      return true unless defined?(::RecordingStudioAccessible)
      return false if actor.blank? || recording.blank?

      RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: role)
    end

    def authorize!(actor:, recording:, role:)
      return if allowed?(actor: actor, recording: recording, role: role)

      raise NotAllowed, "You don't have access to this."
    end
  end
end
