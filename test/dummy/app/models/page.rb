class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace", "Page"]

  RecordingStudio.enable_capability(:categorisable, on: self)
  RecordingStudio.set_capability_options(
    :categorisable,
    on: self,
    references: [
      {
        attribute_name: :status_category_item_recording_id,
        selection: :single,
        category_group_key: "page-status",
        label: "Status"
      },
      {
        attribute_name: :topic_category_item_recording_ids,
        selection: :multiple,
        category_group_key: "page-topics",
        label: "Topics"
      }
    ]
  )

  RecordingStudioCategorisable::Capabilities::Categorisable.apply_for(self)

  validates :title, presence: true 
end
