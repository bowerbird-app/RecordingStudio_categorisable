# frozen_string_literal: true

module RecordingStudioCategorisable
  module CategoryAssignmentsHelper
    def category_item_option_label(recording)
      item = recording.recordable
      "#{item&.category_group&.label} / #{item&.label}"
    end
  end
end
