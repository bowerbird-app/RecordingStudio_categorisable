# frozen_string_literal: true

module RecordingStudioCategorisable
  class Assignment < ApplicationRecord
    self.table_name = "recording_studio_categorisable_assignments"

    recording_studio_recordable(
      label: "Category choice",
      plural_label: "Category choices",
      root: false,
      one_per_parent: true
    )

    validate :category_recording_is_a_category, if: -> { category_recording_id.present? }

    def recordable_name
      "Category choice"
    end
    alias recording_studio_label recordable_name

    private

    def category_recording_is_a_category
      recording = RecordingStudio::Recording.kept.find_by(id: category_recording_id)
      return if recording&.recordable_type == Category.name

      errors.add(:category_recording_id, "must be a category")
    end
  end
end
