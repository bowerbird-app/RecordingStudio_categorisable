# frozen_string_literal: true

module RecordingStudioCategorisable
  class FiltersController < ApplicationController
    def show
      @category = RecordingStudio::Recording.kept.find(params[:id])
      unless @category.recordable_type == Category.name &&
             Access.allowed?(actor: current_actor, recording: @category, role: :view)
        deny_access
        return
      end

      @recordings = RecordingStudioCategorisable.recordings_in_category(@category).includes(:recordable)
    end
  end
end
