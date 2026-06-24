# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryGroup < ActiveRecord::Base
    self.table_name = "recording_studio_categorisable_category_groups"

    has_one :recording, as: :recordable, class_name: "RecordingStudio::Recording", inverse_of: :recordable

    validates :name, presence: true
    validates :key, presence: true

    def usage_count(usage_report = UsageReport.new)
      return 0 unless recording

      usage_report.group_usage_count(recording)
    end
  end
end
