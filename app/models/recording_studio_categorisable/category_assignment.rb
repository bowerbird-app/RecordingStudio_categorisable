# frozen_string_literal: true

module RecordingStudioCategorisable
  # CategoryAssignment links a category item to a target recordable via RecordingStudio.
  # The assignment becomes a child recording of the target and references the category item
  # recording via category_item_recording_id.
  #
  # Relationships:
  # - Belongs to a category item recording (via foreign key)
  # - Belongs to a target recordable via RecordingStudio parent_recording
  #
  class CategoryAssignment < ApplicationRecord
    self.table_name = "recording_studio_categorisable_category_assignments"

    validates :category_item_recording_id, presence: true

    # Validate that the category item recording exists and is the right type
    validate :category_item_recording_must_exist

    # Get the RecordingStudio::Recording wrapper for this assignment
    def recording
      @recording ||= RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
    end

    # Get the category item recording reference
    def category_item_recording
      @category_item_recording ||= RecordingStudio::Recording.find_by(id: category_item_recording_id)
    end

    def category_item_recording=(rec)
      self.category_item_recording_id = rec&.id
      @category_item_recording = rec
    end

    # Convenience method to get the category item recordable
    def category_item
      category_item_recording&.recordable
    end

    # Query helper to find the target recording this assignment belongs to
    def target_recording
      recording&.parent_recording
    end

    # Convenience method to get the target recordable
    def target_recordable
      target_recording&.recordable
    end

    private

    def category_item_recording_must_exist
      return if category_item_recording_id.blank?

      rec = RecordingStudio::Recording.find_by(id: category_item_recording_id)
      if rec.nil?
        errors.add(:category_item_recording_id, "must reference a valid recording")
      elsif rec.recordable_type != "RecordingStudioCategorisable::CategoryItem"
        errors.add(:category_item_recording_id, "must reference a CategoryItem recording")
      end
    end
  end
end
