# frozen_string_literal: true

RecordingStudioCategorisable.configure do |config|
  # Optional heading used by the mounted UI.
  # config.ui_title = "Categories"

  # Resolve the current root recording used by the engine UI.
  # config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }

  # Explicitly register categorisable recordables if you prefer initializer-based configuration.
  # config.register_categorisable("Page") do |registration|
  #   registration.single_select :status_category_item_recording_id, category_group_slug: "page-status"
  #   registration.multi_select :topic_category_item_recording_ids, category_group_slug: "page-topics"
  # end
end
