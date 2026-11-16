# frozen_string_literal: true

module RecordingStudioCategorisable
  class Category < ApplicationRecord
    self.table_name = "recording_studio_categorisable_categories"

    validates :name, presence: true, length: { maximum: 255 }

    def self.sync_declaration!
      RecordingStudio::RecordableDeclarations.install_active_record_macro!
      recording_studio_recordable(
        label: "Category",
        plural_label: "Categories",
        root: false,
        allowed_parent_types: parent_type_names
      )
    end

    def self.parent_type_names
      [name, *RecordingStudioCategorisable.configuration.category_holder_types].uniq
    end

    def recordable_name
      name.presence || "Category"
    end
    alias recording_studio_label recordable_name

    sync_declaration!
  end
end
