# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Temporary compatibility for the installed recording_studio_orderable branch,
  # which registers RecordingStudio::RecordingStudioOrder without declaring
  # recording_studio_recordable(...).
  config.require_recordable_declarations = false

  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = (
    Array(config.recordable_types) + ["Workspace", "Page", "Brief", "RecordingStudioAdmin::Admin"]
  ).uniq

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup

  # Built-in capabilities remain disabled until you opt a recordable type into
  # them by including the relevant RecordingStudio capability module.
end
