class Page < ApplicationRecord
  include RecordingStudioCategorisable::Categorisable

  recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace", "Page"]

  categorises :status_category_item_recording_id, selection: :single, category_group_slug: "page-status", label: "Status"
  categorises :topic_category_item_recording_ids, selection: :multiple, category_group_slug: "page-topics", label: "Topics"

  validates :title, presence: true
end
