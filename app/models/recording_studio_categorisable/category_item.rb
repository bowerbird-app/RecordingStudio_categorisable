# frozen_string_literal: true

module RecordingStudioCategorisable
  class CategoryItem < ActiveRecord::Base
    self.table_name = "recording_studio_categorisable_category_items"

    has_one :recording, as: :recordable, class_name: "RecordingStudio::Recording", inverse_of: :recordable

    before_validation :assign_key_from_name, on: :create

    validates :name, presence: true
    validates :key, presence: true

    def usage_count(usage_report = UsageReport.new)
      return 0 unless recording

      usage_report.item_usage_count(recording)
    end

    private

    def assign_key_from_name
      return if key.present?
      return if name.blank?

      self.key = name.to_s.parameterize
    end
  end
end
