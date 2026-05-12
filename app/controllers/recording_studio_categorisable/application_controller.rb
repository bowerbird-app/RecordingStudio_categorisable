# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception
    before_action :authorize_recording_studio_categorisable_access!

    helper_method :current_root_recording, :parent_recording_options

    private

    def current_root_recording
      return super if defined?(super)

      root_recording = RecordingStudioCategorisable.configuration.resolve_root_recording(self)

      @current_root_recording ||= root_recording.tap do |resolved_root_recording|
        if resolved_root_recording.blank?
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

    def authorize_recording_studio_categorisable_access!
      return super if defined?(super)

      if respond_to?(:authorize_recording_studio_categorisable!, true)
        return if authorize_recording_studio_categorisable!

        raise UnauthorizedError, "You are not authorized to manage categories"
      end

      RecordingStudioCategorisable.configuration.authorize!(self)
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
