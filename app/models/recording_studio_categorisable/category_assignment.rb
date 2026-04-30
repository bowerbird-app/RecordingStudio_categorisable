# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryAssignment < ApplicationRecord
    self.table_name = "recordables"

    validates :category_item_recording_id, presence: true

    # Get the category item recording reference
    def category_item_recording
      RecordingStudio::Recording.find_by(id: category_item_recording_id)
    end

    def category_item_recording=(recording)
      self.category_item_recording_id = recording.id
    end

    # Convenience method to get the category item recordable
    def category_item
      category_item_recording&.recordable
    end

    # Query helper to find the target recording this assignment belongs to
    def target_recording
      recording = RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
      recording&.parent
    end
  end
end
