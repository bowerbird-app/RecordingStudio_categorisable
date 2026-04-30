# frozen_string_literal: true

module RecordingStudioCategorisable
  # CategoryGroup is a top-level container for organizing category items.
  # It hangs off a parent recording (workspace or other root recordable) via RecordingStudio.
  #
  # Relationships:
  # - Has many child category items via RecordingStudio parent/child recordings
  # - Accessed via recording.recordable pattern
  #
  class CategoryGroup < ApplicationRecord
    self.table_name = "recording_studio_categorisable_category_groups"

    validates :label, presence: true, length: { maximum: 255 }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # Get the RecordingStudio::Recording wrapper for this group
    def recording
      @recording ||= RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
    end

    # Query helper to find all category item recordings within this group
    def category_item_recordings
      return RecordingStudio::Recording.none unless recording

      recording.child_recordings.where(
        recordable_type: "RecordingStudioCategorisable::CategoryItem"
      )
    end

    # Convenience method to get category items directly
    def category_items
      category_item_recordings.includes(:recordable).map(&:recordable).compact
    end
  end
end
