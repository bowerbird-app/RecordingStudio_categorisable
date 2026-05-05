# frozen_string_literal: true

module RecordingStudioCategorisable
  module CategoryAssignmentsHelper
    def target_recording_title(recording)
      recordable = recording&.recordable
      recordable&.try(:title) || recordable&.try(:name) || recordable&.try(:label) || recording&.id.to_s
    end

    def category_item_option_label(recording)
      item = recording.recordable
      "#{item&.category_group&.label} / #{item&.label}"
    end
  end
end
