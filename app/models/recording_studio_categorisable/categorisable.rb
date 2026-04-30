# frozen_string_literal: true

module RecordingStudioCategorisable
  module Categorisable
    extend ActiveSupport::Concern

    def recording
      @recording ||= RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
    end

    def category_assignment_recordings
      return RecordingStudio::Recording.none unless recording

      recording.child_recordings.where(
        recordable_type: "RecordingStudioCategorisable::CategoryAssignment",
        trashed_at: nil
      )
    end

    def category_assignments
      category_assignment_recordings.includes(:recordable).map(&:recordable).compact
    end

    def assigned_category_items
      category_assignments.map(&:category_item).compact
    end

    def has_category?(category_item)
      return false unless category_item.is_a?(CategoryItem) && category_item.recording

      category_assignments.any? { |assignment| assignment.category_item_recording_id == category_item.recording.id }
    end

    def assign_category(category_item, actor: nil)
      return false unless recording && category_item.is_a?(CategoryItem) && category_item.recording
      return true if has_category?(category_item)

      recording.record(CategoryAssignment, actor: actor, parent_recording: recording) do |assignment|
        assignment.category_item_recording_id = category_item.recording.id
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def unassign_category(category_item, actor: nil)
      return false unless category_item.is_a?(CategoryItem) && category_item.recording

      assignment_recording = category_assignment_recordings.find do |recording_item|
        recording_item.recordable&.category_item_recording_id == category_item.recording.id
      end

      return false unless assignment_recording

      (assignment_recording.root_recording || assignment_recording).trash(assignment_recording, actor: actor)
      true
    end
  end
end
