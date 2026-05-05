# frozen_string_literal: true

module RecordingStudioCategorisable
  module RecordingRelations
    module_function

    def active(relation)
      return relation.recording_studio_trashable_active if relation.respond_to?(:recording_studio_trashable_active)

      relation.where(trashed_at: nil)
    end

    def root_for(recording)
      return unless recording

      recording.root_recording || recording
    end
  end
end
