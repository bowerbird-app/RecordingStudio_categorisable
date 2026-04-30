# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItem < ApplicationRecord
    self.table_name = "recordables"

    validates :label, presence: true

    # Query helper to find the parent category group
    def category_group
      recording = RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
      return nil unless recording&.parent

      recording.parent.recordable if recording.parent.recordable_type == "RecordingStudioCategorisable::CategoryGroup"
    end

    # Query helper to find all assignments of this category item
    def category_assignments
      recording = RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
      return CategoryAssignment.none unless recording

      # Find all CategoryAssignments that reference this category item recording
      CategoryAssignment.where(category_item_recording_id: recording.id)
    end
  end
end
