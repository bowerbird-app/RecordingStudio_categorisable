# frozen_string_literal: true

RecordingStudioCategorisable.configure do |config|
  config.root_recording_resolver = lambda do |controller:|
    workspace = Workspace.first
    next nil unless workspace

    RecordingStudio::Recording.find_by(
      recordable_type: "Workspace",
      recordable_id: workspace.id
    )
  end
end
