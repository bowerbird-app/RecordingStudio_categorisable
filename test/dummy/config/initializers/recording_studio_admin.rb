# frozen_string_literal: true

if defined?(RecordingStudioAdmin)
  RecordingStudioAdmin.configure do |config|
    config.current_root_recording_resolver = lambda do |controller:, actor:|
      next if actor.blank?

      RecordingStudio::Recording.unscoped.find_by(
        recordable_type: "RecordingStudioAdmin::Admin",
        parent_recording_id: nil
      )
    end

    config.mounted_page_authorizer = lambda do |actor:, root_recording:, **|
      actor.present? && root_recording.present? && actor.respond_to?(:email) && actor.email == "admin@admin.com"
    end
  end
end