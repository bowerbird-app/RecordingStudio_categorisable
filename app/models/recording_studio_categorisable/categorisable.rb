# frozen_string_literal: true

module RecordingStudioCategorisable
  module Categorisable
    extend ActiveSupport::Concern

    include RecordingBacked

    def category_assignment_recordings
      return RecordingStudio::Recording.none unless recording

      RecordingRelations.active(recording.child_recordings).where(recordable_type: "RecordingStudioCategorisable::CategoryAssignment")
    end

    def category_assignments
      category_assignment_recordings.includes(:recordable).map(&:recordable).compact
    end

    def assigned_category_items
      category_assignments.map(&:category_item).compact
    end

    def category_assigned?(category_item)
      return false unless category_item.is_a?(CategoryItem) && category_item.recording

      category_assignments.any? { |assignment| assignment.category_item_recording_id == category_item.recording.id }
    end

    def assign_category(category_item, actor: nil)
      return false unless recording && category_item.is_a?(CategoryItem) && category_item.recording
      return true if category_assigned?(category_item)

      recording.record(CategoryAssignment.new, actor: actor, parent_recording: recording) do |assignment|
        assignment.category_item_recording_id = category_item.recording.id
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def remove_category(category_item, actor: nil)
      return false unless category_item.is_a?(CategoryItem) && category_item.recording

      assignment_recording = category_assignment_recordings.find do |recording_item|
        recording_item.recordable&.category_item_recording_id == category_item.recording.id
      end

      return false unless assignment_recording

      if assignment_recording.respond_to?(:recording_studio_trashable_trash!)
        assignment_recording.recording_studio_trashable_trash!(actor: actor)
      else
        (assignment_recording.root_recording || assignment_recording).trash(assignment_recording, actor: actor)
      end
      true
    end
  end
end
