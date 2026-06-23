# frozen_string_literal: true

module RecordingStudioAdmin
  class Admin < ApplicationRecord
    include RecordingStudioAccessible::AllowsAccessibleChildren if defined?(RecordingStudioAccessible::AllowsAccessibleChildren)

    recording_studio_recordable label: "Admin", root: true

    recording_studio_accessible_children(:access) if respond_to?(:recording_studio_accessible_children)
  end
end