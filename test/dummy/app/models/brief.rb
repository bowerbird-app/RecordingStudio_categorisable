class Brief < ApplicationRecord
  recording_studio_recordable label: "Brief", root: false, allowed_parent_types: ["Workspace", "Page"]

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
      }
    ]
  )

  RecordingStudioCategorisable::Capabilities::Categorisable.apply_for(self)

  validates :title, presence: true
end
