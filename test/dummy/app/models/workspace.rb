class Workspace < ApplicationRecord
  recording_studio_recordable label: "Workspace", root: true
  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)

  if defined?(RecordingStudioCategorisable)
    RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
      key: "page-status",
      name: "Page Status",
      root_recordable_type: name,
      allow: {
        rename: true,
        reorder: false,
        move: false,
        update_description: false
      }
    )

    RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
      key: "page-topics",
      name: "Page Topics",
      root_recordable_type: name,
      allow: {
        rename: false,
        reorder: false,
        move: false,
        update_description: false
      }
    )

    RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
      group_key: "page-status",
      root_recordable_type: name,
      allow: {
        create: true,
        update_name: true,
        update_description: true,
        update_position: false,
        delete: false
      }
    )

    RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
      group_key: "page-topics",
      root_recordable_type: name,
      allow: {
        create: false,
        update_name: false,
        update_description: false,
        update_position: false,
        delete: true
      }
    )

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
  end
end
