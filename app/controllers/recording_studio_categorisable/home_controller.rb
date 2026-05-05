# frozen_string_literal: true

module RecordingStudioCategorisable
  class HomeController < ApplicationController
    def index
      root = current_root_recording
      @category_groups = if root
                           active_recordings(root.child_recordings)
                             .where(recordable_type: CategoryGroup.name)
                             .includes(:recordable)
                             .sort_by { |recording| recording.recordable&.label.to_s.downcase }
                         else
                           []
                         end
    end
  end
end
