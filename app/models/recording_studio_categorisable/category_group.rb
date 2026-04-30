# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroup < ApplicationRecord
    self.table_name = "recordables"

    validates :label, presence: true

    # Query helper to find all category items within this group
    def category_items
      recording = RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
      return CategoryItem.none unless recording

      RecordingStudio::Recording
        .where(parent_id: recording.id, recordable_type: "RecordingStudioCategorisable::CategoryItem")
        .includes(:recordable)
        .map(&:recordable)
    end
  end
end
