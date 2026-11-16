# frozen_string_literal: true

module RecordingStudioCategorisable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception if superclass == ActionController::Base

    helper CategoryHelper

    private

    def current_actor
      return Current.actor if defined?(Current) && Current.respond_to?(:actor)

      nil
    end

    def visible_root_recordings
      types = RecordingStudioCategorisable.configuration.category_holder_types
      return RecordingStudio::Recording.none if types.empty?

      RecordingStudio::Recording.kept.where(recordable_type: types, parent_recording_id: nil).select do |recording|
        Access.allowed?(actor: current_actor, recording: recording, role: :view)
      end
    end

    def categories_under(roots)
      root_ids = roots.map(&:id)
      return [] if root_ids.empty?

      RecordingStudio::Recording.kept
                                .where(root_recording_id: root_ids, recordable_type: Category.name)
                                .includes(:recordable, :parent_recording)
                                .sort_by { |recording| [recording.depth, recording.recordable.name.to_s.downcase] }
    end

    def deny_access
      redirect_back fallback_location: root_path, alert: "You don't have access to this."
    end
  end
end
