class Brief < ApplicationRecord
  include RecordingStudioCategorisable::Categorisable

  recording_studio_recordable label: "Brief", root: false, allowed_parent_types: ["Workspace", "Page"]

  categorises :status_category_item_recording_id, selection: :single, category_group_key: "page-status", label: "Status"

  validates :title, presence: true
end
