# frozen_string_literal: true

module RecordingStudioCategorisable
  module CategoryHelper
    def recording_studio_category_picker(recording)
      render "recording_studio_categorisable/category_choices/picker",
             recording: recording,
             form_path: recording_studio_categorisable.recording_category_path(recording)
    end

    def recording_studio_category_options(root_recording)
      categories = RecordingStudio::Recording.kept
                                             .where(root_recording_id: root_recording.id, recordable_type: RecordingStudioCategorisable::Category.name)
                                             .includes(:recordable)
                                             .sort_by { |recording| recording.recordable.name.to_s.downcase }
      categories.map { |recording| [recording.recordable.name, recording.id] }
    end
  end
end
