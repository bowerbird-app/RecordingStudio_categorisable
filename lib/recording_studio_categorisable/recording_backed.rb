# frozen_string_literal: true

require "active_support/concern"

module RecordingStudioCategorisable
  module RecordingBacked
    extend ActiveSupport::Concern

    def recording
      @recording ||= RecordingStudio::Recording.find_by(
        recordable_type: self.class.name,
        recordable_id: id
      )
    end
  end
end
