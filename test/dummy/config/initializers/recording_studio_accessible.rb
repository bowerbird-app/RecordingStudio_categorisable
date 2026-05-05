# frozen_string_literal: true

Rails.application.config.to_prepare do
  next unless defined?(RecordingStudioAccessible::AllowsAccessibleChildren)

  Workspace.include(RecordingStudioAccessible::AllowsAccessibleChildren) unless Workspace < RecordingStudioAccessible::AllowsAccessibleChildren
  Workspace.recording_studio_accessible_children :access
end
