# frozen_string_literal: true

module RecordingStudioCategorisable
  # CategoryItem represents an individual item within a category group.
  # It hangs off its parent category group recording via RecordingStudio and can be
  # assigned to target recordables via CategoryAssignment.
  #
  # Relationships:
  # - Belongs to a category group via RecordingStudio parent_recording
  # - Can be assigned to multiple target recordables via CategoryAssignment
  #
  class CategoryItem < ApplicationRecord
    include RecordingBacked

    self.table_name = "recording_studio_categorisable_category_items"

    validates :label, presence: true, length: { maximum: 255 }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :color, length: { maximum: 50 }, allow_blank: true

    # Query helper to find the parent category group
    def category_group
      return nil unless recording&.parent_recording

      return unless recording.parent_recording.recordable_type == "RecordingStudioCategorisable::CategoryGroup"

      recording.parent_recording.recordable
    end

    # Query helper to find all assignments of this category item
    def category_assignments
      return CategoryAssignment.none unless recording

      # Find all CategoryAssignments that reference this category item recording
      CategoryAssignment.where(category_item_recording_id: recording.id)
    end
  end
end
