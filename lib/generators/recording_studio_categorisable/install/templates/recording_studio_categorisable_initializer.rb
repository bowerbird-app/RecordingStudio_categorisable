# frozen_string_literal: true

RecordingStudioCategorisable.configure do |config|
  # Optional heading used by the mounted UI.
  # config.ui_title = "Categories"

  # Resolve the current root recording used by the engine UI.
  # config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }

  # Required unless your ApplicationController defines
  # `authorize_recording_studio_categorisable!`.
  # config.authorization_resolver = ->(controller) { controller.current_user.present? }

  # Optional: customize unauthorized behavior for the mounted UI.
  # The handler should perform a response (render/redirect/head).
  # config.unauthorized_response_handler = ->(controller, exception) do
  #   controller.render("errors/forbidden", status: :forbidden)
  # end

  # Explicitly register categorisable recordables if you prefer initializer-based configuration.
  # config.register_categorisable("Page") do |registration|
  #   registration.single_select :status_category_item_recording_id, category_group_key: "page-status"
  #   registration.multi_select :topic_category_item_recording_ids, category_group_key: "page-topics"
  # end
end
