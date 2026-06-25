class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  RecordingStudio.enable_capability(:accessible, on: self)

  RecordingStudio.enable_capability(:categorisable, on: self)
  RecordingStudio.set_capability_options(
    :categorisable,
    on: self,
    category_groups: [
      {
        key: "page-status",
        allow: {
          rename: true,
          update_description: false
        }
      },
      {
        key: "page-topics",
        allow: {
          rename: false,
          update_description: false
        }
      }
    ],
    category_items: [
      {
        group_key: "page-status",
        allow: {
          create: true,
          update_name: true,
          update_description: true,
          orderable: false,
          delete: false
        }
      },
      {
        group_key: "page-topics",
        allow: {
          create: false,
          update_name: false,
          update_description: false,
          orderable: false,
          delete: true
        }
      }
    ],
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
end
