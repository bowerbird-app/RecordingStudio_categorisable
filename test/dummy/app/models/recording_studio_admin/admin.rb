# frozen_string_literal: true

module RecordingStudioAdmin
  class Admin < ApplicationRecord
    include RecordingStudioAccessible::AllowsAccessibleChildren if defined?(RecordingStudioAccessible::AllowsAccessibleChildren)

    recording_studio_recordable label: "Admin", root: true
    RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)

    recording_studio_accessible_children(:access) if respond_to?(:recording_studio_accessible_children)

    if defined?(RecordingStudioCategorisable)
      RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
        key: "page-status",
        name: "Page Status",
        root_recordable_type: name,
        allow: {
          rename: false,
          reorder: false,
          move: false,
          update_description: false,
        }
      )

      RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
        key: "page-topics",
        name: "Page Topics",
        root_recordable_type: name,
        allow: {
          rename: true,
          reorder: false,
          move: true,
          update_description: true,
        }
      )

      RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
        key: "color",
        name: "Color",
        root_recordable_type: name,
        allow: {
          rename: true,
          reorder: true,
          move: true,
          update_description: true,
        }
      )

      RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
        group_key: "page-status",
        root_recordable_type: name,
        allow: {
          create: true,
          update_name: false,
          update_position: false,
          update_description: false,
          delete: false
        }
      )

      RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
        group_key: "page-topics",
        root_recordable_type: name,
        allow: {
          create: true,
          update_name: true,
          update_position: true,
          update_description: true,
          delete: true
        }
      )

      RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
        group_key: "color",
        root_recordable_type: name,
        allow: {
          create: true,
          update_name: true,
          update_position: true,
          update_description: true,
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
end