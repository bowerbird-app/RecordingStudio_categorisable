# frozen_string_literal: true

module RecordingStudioCategorisable
  module RecordingSupport
    private

    def active_recordings(relation)
      RecordingRelations.active(relation)
    end

    def active_recording_scope
      active_recordings(RecordingStudio::Recording.all)
    end

    def root_recording_for(recording)
      RecordingRelations.root_for(recording)
    end

    def create_child_recording!(parent_recording:, recordable:)
      parent_recording.record(
        recordable,
        actor: current_recording_studio_actor,
        parent_recording: parent_recording
      )
    end

    def prepare_recordable(recording:, attributes:)
      recordable = recording.recordable.dup
      recordable.assign_attributes(attributes)
      recordable
    end

    def revise_recording!(recording:, attributes:)
      root_recording_for(recording).revise(recording, actor: current_recording_studio_actor) do |recordable|
        recordable.assign_attributes(attributes)
      end
    end

    def trash_recording!(recording:, metadata: {})
      if recording.respond_to?(:recording_studio_trashable_trash!)
        recording.recording_studio_trashable_trash!(
          actor: current_recording_studio_actor,
          impersonator: current_recording_studio_impersonator,
          metadata: metadata
        )
      else
        root_recording_for(recording).trash(recording, actor: current_recording_studio_actor)
      end
    end

    def find_child_recording!(parent_recording:, id:, recordable_type:)
      active_recordings(parent_recording.child_recordings).find_by!(id: id, recordable_type: recordable_type)
    end
  end
end
