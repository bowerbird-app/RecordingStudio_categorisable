class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace", "Page"]

  RecordingStudioCategorisable::Capabilities::Reference.enabled(
    recordable: self,
    attribute_name: :status_category_item_recording_id,
    selection: :single,
    category_group_key: "page-status",
    label: "Status"
  )

  RecordingStudioCategorisable::Capabilities::Reference.enabled(
    recordable: self,
    attribute_name: :topic_category_item_recording_ids,
    selection: :multiple,
    category_group_key: "page-topics",
    label: "Topics"
  )

  validates :title, presence: true 
end
