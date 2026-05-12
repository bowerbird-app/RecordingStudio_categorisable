# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception

    helper_method :current_root_recording, :parent_recording_options

    private

    def current_root_recording
      return super if defined?(super)

      configuration = RecordingStudioCategorisable.configuration
      resolver = configuration.resolve_root_recording(self)

      @current_root_recording ||= resolver.tap do |root_recording|
        if root_recording.blank?
          raise MissingRootRecordingError,
                "A root recording resolver is required for RecordingStudioCategorisable"
        end
      end
    end

    def load_recording(recordable_type)
      current_root_recording
        .recordings_query(include_children: true, type: recordable_type)
        .includes(:recordable)
        .find(params[:id])
    end

    def parent_recording_options
      current_root_recording
        .recordings_query(include_children: true)
        .includes(:recordable)
        .map do |recording|
          [
            "#{recording.recordable_type.demodulize}: #{recording_label(recording)}",
            recording.id
          ]
        end
    end

    def recording_label(recording)
      recordable = recording.recordable
      return recordable.name if recordable.respond_to?(:name)
      return recordable.title if recordable.respond_to?(:title)

      recordable.class.model_name.human
    end
  end
end
