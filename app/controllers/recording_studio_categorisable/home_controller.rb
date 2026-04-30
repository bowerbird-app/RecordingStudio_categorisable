# frozen_string_literal: true

module RecordingStudioCategorisable
  class HomeController < ApplicationController
    def index
      @category_groups = RecordingStudio::Recording.where(
        recordable_type: "RecordingStudioCategorisable::CategoryGroup"
      ).includes(:recordable).order("recordables.label ASC")
    end
  end
end
